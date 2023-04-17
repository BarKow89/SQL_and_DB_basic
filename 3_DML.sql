/*
TASK 1
    1.1	Choose your top-3 favorite movies and add them to the 'film' table. Fill rental rates with 4.99, 9.99, and 19.99 and rental durations with 1, 2 and 3
    	weeks respectively
    1.2  Add actors who play leading roles in your favorite movies to 'actor' and 'film_actor' tables (6 or more actors in total).
    1.3 Add your favorite movies to any store's inventory.
*/

WITH new_films AS                                                                                                             -- Table creation with all new movies data (3 movies so UNION ALL was used 2 times)    
    (
    SELECT  'ROOM'  AS title, 
            'An emotional drama about a young mother and her son who have been held 
            captive in a small shed for years and their struggle to adjust to the 
            outside world after escaping.'   AS description,
            2016    AS release_year,
            (SELECT l.language_id FROM public."language" l  WHERE lower(l.name) = 'english') AS language_id,
            (SELECT l.language_id FROM public."language" l  WHERE lower(l.name) = 'english') AS original_language_id,
            1       AS rental_duration,
            4.99    AS rental_rate,
            118     AS length,
            19.99   AS replacement_cost,
            CAST('R' AS mpaa_rating)     AS rating
   
    UNION ALL      
    SELECT  'GRAN TORINO'  AS title, 
            'A drama about a retired auto worker who forms an unlikely friendship 
             with a Hmong teenager.'   AS description,
            2008    AS release_year,
            (SELECT l.language_id FROM public."language" l  WHERE lower(l.name) = 'english') AS language_id,
            (SELECT l.language_id FROM public."language" l  WHERE lower(l.name) = 'english') AS original_language_id,
            2       AS rental_duration,
            9.99    AS rental_rate,
            116     AS length,
            19.99   AS replacement_cost,
            CAST('R' AS mpaa_rating)     AS rating
    
    UNION ALL 
    SELECT  'LITTLE MISS SUNSHINE' AS title, 
            'A heartwarming comedy-drama about a dysfunctional family who embarks
             on a road trip to support their daughters dream of participating in 
             a beauty contest' AS description, 
             2006   AS release_year,
            (SELECT l.language_id FROM public."language" l  WHERE lower(l.name) = 'english') AS language_id,
            (SELECT l.language_id FROM public."language" l  WHERE lower(l.name) = 'english') AS original_language_id,
            3       AS rental_duration,
            19.99   AS rental_rate,
            141     AS length,
            19.99   AS replacement_cost,
            CAST('R' AS mpaa_rating)     AS rating        
    ),
    
    new_actors  AS                                                                                                          -- List of actors with films assigned
    (SELECT  'CLINT'  AS first_name,   'EASTWOOD' AS last_name, 'GRAN TORINO'  AS title
    UNION ALL
    SELECT  'BEE'     , 'VANG'      ,   'GRAN TORINO'
    UNION ALL
    SELECT  'ABIGAIL' , 'BRESLIN'   ,   'LITTLE MISS SUNSHINE'
    UNION ALL
    SELECT  'PAUL'    , 'DANO'      ,   'LITTLE MISS SUNSHINE'
    UNION ALL
    SELECT  'STEVE'   , 'CARELL'    ,   'LITTLE MISS SUNSHINE'
    UNION ALL
    SELECT  'JACOB'   , 'TREMBLAY'  ,   'ROOM'
    UNION ALL
    SELECT  'BIRE'    , 'LARSON'    ,   'ROOM'
    ),
    
   inserting_actors   AS
    (
    INSERT INTO public.actor (first_name, last_name)
    SELECT  first_name, last_name 
    FROM    new_actors na
    WHERE NOT EXISTS   (SELECT *
                        FROM public.actor a 
                        WHERE   a.first_name = na.first_name AND  a.last_name = na.last_name) 
    RETURNING actor_id, first_name, last_name
    ),

    inserting_films    AS 
    (
    INSERT INTO public.film (title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating)
    SELECT  title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating
    FROM    new_films nf
    WHERE NOT EXISTS    (SELECT *
                         FROM public.film f
                         WHERE f.title = nf.title AND f.release_year = nf.release_year) 
    RETURNING film_id, title, description, release_year, language_id, original_language_id, rental_duration, rental_rate, length, replacement_cost, rating
    ),
    
    inserting_film_actor    AS 
    (    
    INSERT INTO public.film_actor 
    SELECT ia.actor_id, inf.film_id
    FROM inserting_actors ia
    INNER JOIN new_actors na
        ON  ia.first_name   =   na.first_name AND ia.last_name = na.last_name
    INNER JOIN inserting_films inf
        ON  na.title        =   inf.title
    RETURNING actor_id, film_id
    ),


    adding_to_inventory     AS 
    (
    INSERT INTO public.inventory (film_id, store_id)
    SELECT film_id, (SELECT 1)
    FROM inserting_films
    RETURNING inventory_id, film_id, store_id
    )
 
SELECT * FROM adding_to_inventory;
    
																					
/* 
1.4 Alter any existing customer in the database who has at least 43 rental and 43 payment records. Change his/her personal data to yours (first name,
	last name, address, etc.). Do not perform any updates on 'address' table, as it can impact multiple records with the same address. Change
	customer's create_date value to current_date
*/

UPDATE 	customer 
SET 	first_name	=	'Barbara',
    	last_name	=	'Kowalczyk',
    	email 		=	'barbara.pkowalczyk@gmail.com',
    	address_id 	=	(SELECT address_id  FROM public.address  ORDER BY RANDOM() LIMIT 1) ,							-- Since there wasn't my addres in a table and in the description it was said to not change the address table, I used a random command to get any address from the address_column 
    	create_date =	current_date 
    		
WHERE customer_id 	=	(SELECT c.customer_id																			-- I used a subquery to pick the first customer_id which meets the requirements		
						FROM customer c 
						INNER JOIN rental r 	ON		c.customer_id 	=	r.customer_id 
						INNER JOIN payment p 	ON		r.customer_id 	=	p.customer_id 
									
						GROUP BY c.customer_id
						HAVING 	COUNT(DISTINCT r.rental_id)		>= 	43		AND 	
								COUNT(DISTINCT p.payment_id)	>=	43
									
						LIMIT 1)
	AND NOT EXISTS (SELECT * FROM public.customer c 
	                WHERE   first_name  =   'Barbara' AND 
                            last_name   =   'Kowalczyk' AND  
                            email       =   'barbara.pkowalczyk@gmail.com' )    
						
RETURNING customer_id, first_name, last_name, email, address_id, create_date;																			



-- 1.5 Remove any records related to you (as a customer) from all tables except 'Customer' and 'Inventory'


WITH 	del_payment AS 
					(	
					DELETE FROM payment 					                                                                                                                          -- I deleted the data related to  new customer from the payment table first and after that did the same with rental table.																
					WHERE customer_id = (  SELECT customer_id 
					                       FROM public.customer c 
					                       WHERE   first_name  = 'Barbara'     AND 
					                               last_name   = 'Kowalczyk'   AND     
					                               email       = 'barbara.pkowalczyk@gmail.com')
					RETURNING customer_id, payment_id   
					),
		del_rental	AS	
					(
					DELETE FROM rental						                                                                                                                           -- Second step: Deleting the data from  rental. This order was conditioned by the fact  that rental_id is a FK in a payment table. 
					WHERE customer_id = (  SELECT customer_id 
					                       FROM public.customer c 
					                       WHERE   first_name = 'Barbara'     AND    
					                               last_name  = 'Kowalczyk'   AND 
					                               email      = 'barbara.pkowalczyk@gmail.com')
					RETURNING customer_id, rental_id 
					)
SELECT *
FROM del_payment dp
FULL JOIN 	del_rental	dr	ON	dp.customer_id 	=	dr.customer_id
INNER JOIN customer c2 ON dr.customer_id = c2.customer_id;
					
-- The query will show me all rental and payment and details which were deleted.


/*
 1.6	Rent you favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
 		Note: 	to insert the payment_date into the table payment, you can create a new partition (see the scripts to install the training database ) or add records for the
				first half of 2017.
*/


--I am adding  records for the first half of 2017

WITH my_films   AS 
    (
    SELECT '2017-06-29'   AS rental_date,
            i.inventory_id, 
            c.customer_id,
            '2017-06-30'  AS return_date,
            (SELECT staff_id  FROM public.staff s  ORDER BY RANDOM() LIMIT 1) AS staff_id 
    FROM public.inventory i 
    CROSS JOIN public.customer c 
    WHERE   film_id IN (SELECT film_id FROM public.film f WHERE f.title IN ('ROOM','GRAN TORINO','LITTLE MISS SUNSHINE')) AND 
            c.email = 'barbara.pkowalczyk@gmail.com'
    ),
    
    my_rentals  AS 
    (
    INSERT INTO rental 	(rental_date,	inventory_id,	customer_id,	return_date,	staff_id)
        SELECT 	CAST(rental_date AS  DATE),    inventory_id,   customer_id,    CAST(return_date AS DATE), staff_id 
        FROM my_films
    RETURNING rental_id, rental_date,  inventory_id,   customer_id,    return_date,    staff_id
    )

INSERT INTO payment (customer_id, staff_id, rental_id, amount, payment_date)			-- choosing the columns which will be filled in with new data
SELECT	mr.customer_id,																	-- I added the data from the my_rental table  which I just created
		mr.staff_id,
		mr.rental_id,
		(SELECT (CASE 																	
					WHEN	mr.inventory_id      = 4602    THEN    4.99                 
					WHEN	mr.inventory_id      =	4603   THEN	   9.99                                                                                                  
					ELSE	19.99                                                                                                                                         
				 END) AS amount),
		mr.rental_date 
FROM my_rentals mr
RETURNING *;




---------------------------------------------------------------------------------
/*
SELECT * FROM inventory i  ORDER BY film_id DESC 
SELECT * FROM film f ORDER BY film_id DESC
SELECT * FROM payment p  ORDER BY payment_id DESC 
SELECT * FROM rental r ORDER BY rental_id DESC 
SELECT * FROM actor ORDER BY actor_id DESC
SELECT * FROM film_actor ORDER BY actor_id DESC
*/