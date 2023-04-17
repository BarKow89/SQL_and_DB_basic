/*
 1. Create a function that will return the most popular film for each country (where country is an input paramenter).
 */
--DROP FUNCTION most_popular_film

CREATE OR REPLACE FUNCTION most_popular_film (
IN country_name_1 TEXT DEFAULT NULL, 
IN country_name_2 TEXT DEFAULT NULL, 
IN country_name_3 TEXT DEFAULT NULL)

RETURNS TABLE (country VARCHAR(30), film_title VARCHAR(30), film_rating MPAA_RATING, film_language VARCHAR(20), film_length SMALLINT, release_year YEAR)

LANGUAGE plpgsql

AS $$

    BEGIN 
    RETURN QUERY  
        WITH film_per_country_rental AS (     -- CTE returns the table of with data refering only to countries being function parameters. It retreives also the sum of rentals made of every filim within a country       
                        SELECT  f.title          AS film_title,
                                c.country        AS country_name,
                                f.rating         AS film_rating,
                                l."name"         AS film_language,
                                f."length"       AS film_length,
                                f.release_year   AS release_year,
                                SUM(r.rental_id) AS total_rentals
                            
                        FROM public.film f
                        INNER JOIN public.inventory i   ON  f.film_id       =   i.film_id
                        INNER JOIN public.rental r      ON  i.inventory_id  =   r.inventory_id
                        INNER JOIN public."language" l  ON  f.language_id   =   l.language_id
                        INNER JOIN public.staff s       ON  r.staff_id      =   s.staff_id 
                        INNER JOIN public.store st      ON  s.store_id      =   st.store_id 
                        INNER JOIN public.address a     ON  st.address_id   =   a.address_id 
                        INNER JOIN public.city ci       ON  a.city_id       =   ci.city_id 
                        INNER JOIN public.country c     ON  ci.country_id   =   c.country_id
                            
                        WHERE   lower(c.country) IN (lower(country_name_1), lower(country_name_2), lower(country_name_3))
                        GROUP BY  f.title, c.country, f.rating, l."name", f."length"  ,f.release_year
                        ORDER BY  c.country,SUM(r.rental_id) DESC ),
            
             film_per_country_max_rental AS (  -- Filtering the film_per_country_rental table to retrieve the table with max valueas per film in defined country only     
                        SELECT  fc1.country_name,
                                fc1.film_title,
                                fc1.film_rating,
                                fc1.film_language,
                                fc1.film_length,
                                fc1.release_year,
                                MAX(fc1.total_rentals)  OVER (PARTITION BY country_name)
                        FROM film_per_country_rental  fc1
                        WHERE fc1.total_rentals IN (SELECT MAX(fc2.total_rentals) 
                                                    FROM film_per_country_rental fc2 
                                                    WHERE fc1.country_name=fc2.country_name))
         SELECT  CAST(fl.country_name AS VARCHAR(30)),
                 CAST(fl.film_title AS VARCHAR(30)),
                 fl.film_rating,
                 CAST(fl.film_language AS VARCHAR(20)),
                 CAST(fl.film_length AS SMALLINT),
                 fl.release_year
         FROM film_per_country_max_rental fl
         ;
   
END; 
$$;

-- SELECT * FROM  most_popular_film('Canada', 'Australia', 'Brasil');

/*
 
 2. Create a function that will return a list of films by part of the title in stock (for example, films with the word 'love' in the title).
    • So, the title of films consists of ‘%...%’, and if a film with the title is out of stock, please return a message: a movie with that title was not found
    • The function should return the result set in the following view (notice: row_num field is generated counter field (1,2, …, 100, 101, …))

*/
-- DROP FUNCTION substring_in_title 
CREATE OR REPLACE FUNCTION substring_in_title (IN title_substring VARCHAR(20))
RETURNS TABLE (row_num BIGINT, film_title VARCHAR(30), "language" VARCHAR(20), customer_name VARCHAR(30), last_rental TIMESTAMP )
LANGUAGE plpgsql
AS 
$$

    BEGIN 
   
        
        CREATE TEMPORARY TABLE title_substring_result
                               (row_num BIGINT, film_title VARCHAR(30), "language" VARCHAR(20), customer_name VARCHAR(30), last_rental TIMESTAMP );
                           
                           
                           
    RETURN QUERY                       
        WITH 
        current_stock AS (                                                             -- Select only film from inventory to be sure that we consider only position which are currently company assets (in rental table are historic data, so it could contain films which are not available anymore)  
                SELECT  i.inventory_id,
                        i.film_id,
                        f.title,
                        l."name"
                 
               FROM public.film f 
               INNER JOIN public."language" l  ON  f.language_id = l.language_id  
               INNER JOIN public.inventory i   ON  f.film_id     = i.film_id),
            
             
        stock_and_last_rental AS (
               SELECT  cs.title     AS film_title,
                       cs."name"    AS "Language",
                       CONCAT(c.first_name,' ',c.last_name)  AS customer_name,
                       r.rental_date,
                       cs.inventory_id
                FROM current_stock cs
                INNER JOIN public.rental r      ON cs.inventory_id = r.inventory_id 
                INNER JOIN public.customer c    ON r.customer_id   = c.customer_id 
                
                WHERE   r.return_date IS NOT NULL                                                     --  movies are available (in stock)  when they are not rented  
                  AND   r.rental_date IN (SELECT MAX(subr.rental_date) 
                                         FROM  public.rental subr
                                         WHERE subr.inventory_id = cs.inventory_id))
       
        INSERT INTO   title_substring_result                      
        SELECT  ROW_NUMBER() OVER () AS row_num,
                CAST(slr.film_title AS VARCHAR(30)),
                CAST(slr."Language" AS VARCHAR(20)),
                CAST(slr.customer_name AS VARCHAR(30)),
                CAST(slr.rental_date AS TIMESTAMP)
        FROM stock_and_last_rental slr               
        WHERE  lower(slr.film_title) LIKE lower(title_substring)
        ORDER BY slr.film_title
        RETURNING *;
    
    IF (SELECT COUNT(tsr.film_title) FROM title_substring_result tsr) = 0 
    THEN RAISE NOTICE 'The movie with " %  in the title does not exist "', title_substring;
    END IF;

    DROP TABLE title_substring_result;
        
END; 
$$;

--  SELECT * FROM substring_in_title('%blablabla%');


/*
 
 3. Create function that inserts new movie with the given name in ‘film’ table. 
    ‘release_year’, ‘language’ are optional arguments and default to current year and
    Klingon respectively. 
    The function must return film_id of the inserted movie.
 */

CREATE OR REPLACE FUNCTION insert_movie (
    new_title TEXT, 
    new_release_year YEAR DEFAULT EXTRACT(YEAR FROM current_date),
    new_language BPCHAR(20) DEFAULT 'Klingon')
RETURNS INT2
LANGUAGE plpgsql
AS $$
DECLARE
    new_language_id INT2;
    new_film_id BIGINT;
BEGIN
    
    
    SELECT l.language_id   INTO new_language_id               -- Check if language exists in language table
    FROM public."language" l
    WHERE lower("name") = lower(new_language);
    
    
    IF new_language_id IS NULL THEN                             -- If language doesn't exist, add it to the language table and retrieve its generated language_id
    INSERT INTO public."language" ("name")
    VALUES (INITCAP(new_language)) 
    RETURNING language_id INTO new_language_id;
    END IF;

    WITH new_film_data AS (                                     -- Insert new movie into film table
        SELECT  new_title::TEXT           AS title, 
                new_release_year::YEAR    AS release_year, 
                new_language_id::INT2     AS language_id )
                
    INSERT INTO public.film (title, release_year, language_id) 
    SELECT *
    FROM new_film_data nf
    WHERE NOT EXISTS (SELECT * FROM public.film f WHERE f.title = nf.title AND f.release_year = nf.release_year)
    RETURNING film_id INTO new_film_id; 

    RETURN new_film_id;
END;
$$;

--SELECT * FROM insert_movie ('Test title 1')
--SELECT * FROM  insert_movie ('Test title 2' , 1999, 'Polish')

--SELECT * FROM public.film  WHERE title LIKE 'Test title%'


/*
4.  Create one function that reports all information for a particular client and timeframe:
        • Customer's name, surname and email address;
        • Number of films rented during specified timeframe;
        • Comma-separated list of rented films at the end of specified time period;
        • Total number of payments made during specified time period;
        • Total amount paid during specified time period;
    Function's input arguments: client_id, left_boundary, right_boundary.
    The function must analyze specified timeframe [left_boundary, right_boundary] and output specified information for this timeframe.
    Function's result format: table with 2 columns ‘metric_name’ and ‘metric_value’.
*/


CREATE OR REPLACE FUNCTION public.client_info (
IN client_id BIGINT, 
IN left_boundary DATE, 
IN right_boundary DATE DEFAULT current_date)

RETURNS TABLE (metric_name TEXT, metric_value TEXT )
LANGUAGE plpgSQL

AS
$$
BEGIN
    RETURN QUERY 
    WITH headline_and_firstrow AS (
             SELECT 'customer''s info'                      AS metric_name_headline,
                    (SELECT first_name||' '||last_name||' , '||email  
                     FROM public.customer 
                     WHERE customer_id::BIGINT = client_id) AS metric_value_headline),
         
         films_rented AS (
             SELECT 'num. of films rented'      AS fr_metric_name,
                    (SELECT COUNT(rental_id) 
                     FROM  public.rental r  
                     WHERE  customer_id::BIGINT = client_id AND 
                            rental_date::DATE BETWEEN left_boundary AND right_boundary
                     GROUP BY customer_id)      AS  fr_metric_value),
        
        rented_films_titles AS (
            SELECT 'rented films'' titles'      AS    rft_metric_name,
                    (SELECT group_concat(f.title ::text) 
                     FROM  public.rental r 
                     LEFT JOIN public.inventory i   ON  r.inventory_id  = i.inventory_id 
                     LEFT JOIN public.film f        ON  i.film_id       = f.film_id
                     WHERE customer_id::BIGINT = client_id
                     GROUP BY customer_id   )   AS rft_metric_value),
                     
        number_of_payments AS (
            SELECT 'num. of payments'           AS nop_metric_name,
                    (SELECT COUNT(payment_id)
                     FROM  public.payment p 
                     WHERE  customer_id::BIGINT = client_id AND 
                            payment_date::DATE BETWEEN left_boundary AND right_boundary
                     GROUP BY customer_id)   AS nop_metric_value),
                
         payments_amount   AS (
            SELECT 'payments'' amount'          AS  pa_metric_name,
                    (SELECT SUM(amount)
                     FROM payment p 
                     WHERE  customer_id::BIGINT = client_id AND 
                            payment_date::DATE BETWEEN left_boundary AND right_boundary
                     GROUP BY customer_id)      AS pa_metric_value)
    
    SELECT  metric_name_headline::TEXT, metric_value_headline::TEXT
    FROM headline_and_firstrow
    
    UNION ALL 
    SELECT fr_metric_name::TEXT, fr_metric_value::TEXT
    FROM films_rented
    
    UNION ALL 
    SELECT  rft_metric_name::TEXT, rft_metric_value::TEXT
    FROM rented_films_titles
    
    UNION ALL 
    SELECT  nop_metric_name::TEXT, nop_metric_value::TEXT
    FROM number_of_payments
    
    UNION ALL 
    SELECT  pa_metric_name::TEXT, pa_metric_value::TEXT
    FROM payments_amount;

    
    
END;
$$;


-- SELECT * FROM public.client_info(3,'2000-01-01', '2022-01-01')
 









