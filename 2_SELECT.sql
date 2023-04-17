
--1.1 All comedy movies released between 2000 and 2004, alphabetical

SELECT 	f.title,																			
		c."name" 		AS 	category, 
		f.release_year 

FROM	film f 																				--  Decided to use simply JOIN since it is more efficent that two nested queries.
INNER JOIN 	film_category fc 	ON		f.film_id 		=	fc.film_id 						--  INNER JOIN because I wanted to retreive ONLY comedies. 
INNER JOIN	category c 			ON 		fc.category_id 	=	c.category_id

WHERE	
		f.release_year	BETWEEN '2000'	AND	'2004'	AND 									-- the best OPTION FOR marking a date range.
		c.name = 'Comedy'																	

ORDER BY	f.title ASC;																	-- Add ASC as it is consider as a good practise even though without it the outcome would be the same




-- 1.2 Revenue of every rental store for year 2017 (columns: address and address2 – as one column, revenue)

SELECT 	st.store_id,																		-- Selected only relevant columns 
		CONCAT(a.address,' , ',a.address2)	AS	address_and_address2,						
		SUM(p.amount)						AS	revenue_in_2017								-- Used SUM to retrieve the incomes per EACH store. I sum the amounts of every single payment done in each store. 
		
FROM		payment p 																		
INNER JOIN 	staff s 	ON 	p.staff_id 		=	s.staff_id									-- Joined extra tables in order to get the address of the stores.
INNER JOIN 	store st 	ON	s.store_id 		=	st.store_id 
INNER JOIN 	address a 	ON	st.address_id 	=	a.address_id

WHERE 	p.payment_date 	BETWEEN '2017-01-01'	AND 	'2017-12-31'						-- Filtering by date range.

GROUP BY 	st.store_id, address_and_address2 ;												



-- 1.3 Top-3 actors by number of movies they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)

SELECT 	a.first_name		AS	actor_first_name,											
		a.last_name			AS 	actor_last_name,
		COUNT(fa.film_id) 	AS	number_of_movies

FROM 	film_actor fa																		--  Joined two tables: film_actor  table (to count movies per actor) and actor table to get actors’ names and last names. 
INNER JOIN	actor a 	ON		fa.actor_id	=	a.actor_id 

GROUP BY	a.first_name, a.last_name														-- Grouped the results by actors. in order to sum up the movies per each actor.
ORDER BY 	number_of_movies DESC															-- Set an order by number of movies from the biggest number to the lowest one. 
LIMIT 3;																					-- Left only three top results.		
			



/* 1.4 Number of comedy, horror and action movies per year (columns: release_year, number_of_action_movies, number_of_horror_movies, number_of_comedy_movies), 
 sorted by release year in descending order */

SELECT 	f.release_year,
		SUM(	CASE	WHEN	c."name" = 'Action'	THEN 1									-- Each time the “action” category occurs in the column, the number 1 is assigned. Then it is summed 
				ELSE 0
				END)										AS number_of_action_movies,		 
		SUM(	CASE	WHEN	c."name" = 'Comedy'	THEN 1									-- Each time the “comedy” category occurs in the column, the number 1 is assigned. Then it is summed 
				ELSE 0
				END)										AS number_of_comedy_movies,
		SUM(	CASE	WHEN	c."name" = 'Horror'	THEN 1									-- Each time the “horror” category occurs in the column, the number 1 is assigned. Then it is summed 
				ELSE 0														
				END)										AS number_of_horror_movies

FROM 	film f																				
INNER JOIN		film_category fc 	ON 		f.film_id 		=	fc.film_id 
INNER JOIN 		category c 			ON		fc.category_id 	=	c.category_id 
												
GROUP BY f.release_year																		
ORDER BY f.release_year DESC;																-- Setting order from the most recent to the odlest 




-- Part 2: Solve the following problems with the help of SQL

-- Which staff members made the highest revenue for each store and deserve a bonus for 2017 year?

WITH revenue_2017 	AS 																						-- Creation of a separate temporary result set which I will use in the next step.	
						(	
						SELECT 	s.store_id,																	--	Selected all the columns needed to identify the employees of each store 
								a.address,
								s.staff_id,
								CONCAT(s.first_name,' ',s.last_name) 	AS	staff_name,
								SUM(p.amount)							AS	revenue_by_staff
						
						FROM	payment p 																	-- Joined all tables needed (tables which contains data I needed, including staff, stores, addresses)
						INNER JOIN	staff s 		ON		p.staff_id		=	s.staff_id 
						INNER JOIN 	store st 		ON		s.store_id 		=	st.store_id 
						INNER JOIN 	address a 		ON		st.address_id 	=	a.address_id 
						
						WHERE p.payment_date BETWEEN '2017-01-01'	AND '2017-12-31'						-- Filtering by year – only payments from 2017 are relevant for that task
						
						GROUP BY s.store_id, a.address,	s.staff_id,	CONCAT(s.first_name,' ',s.last_name)	-- I grouped  in order to get the  sum of amount per each employee (staff member) 
						)
-- At this point I have a table with revenue (money earned) by each employee from all stores. 			
SELECT	r.store_id, 																						-- Retreiving the columns needed
		r.address, 
		r.staff_id, 
		r.staff_name, 
		r.revenue_by_staff
FROM revenue_2017 r																							-- I used a temporary results (table) created before
WHERE revenue_by_staff IN	(																				-- Filtering the results in a way that shows only revenue_by_staff equal to subquery results 
       						SELECT MAX(revenue_by_staff)													-- Subquery which defines the max revenue (max amount from the column)  for every store_id which appreas in the outside query
       						FROM revenue_2017 AS rev
							WHERE rev.store_id = r.store_id
							)
ORDER BY store_id ASC;																						-- just seting order by store id
						
						


-- Which 5 movies were rented more than others and what's expected audience age for those movies?

SELECT	COUNT(r.rental_id)		AS		number_of_rentals,													-- Counted all rental_ids.  The number of rentals is grouped by each title (and rating)
		f.title					AS		movie_title,
		f.rating				AS		mpa_rating,
		CASE	WHEN	f.rating	=	'PG'		THEN 	'Parental Guidance Suggested'					-- Based pn rating each film, it's explanation is provided (to make the reviewer aware what rating exactly mean).  
				WHEN 	f.rating	=	'PG-13'		THEN	'Parents Strongly Cautioned'
				WHEN 	f.rating	=	'NC-17'		THEN 	'Noone 17 and under admitted'
				WHEN 	f.rating	=	'G'			THEN 	'General Audiences'
				WHEN 	f.rating	=	'R'			THEN 	'Restriced'
		END						AS 		rating_description,
		
		CASE	WHEN	f.rating	=	'PG'		THEN 	'from 10 up '									-- For every rating, the age of expected audience is proposed 
				WHEN 	f.rating	=	'PG-13'		THEN	'from 13 up'
				WHEN 	f.rating	=	'NC-17'		THEN 	'from 17 up'
				WHEN 	f.rating	=	'G'			THEN 	'from 0 up'
				WHEN 	f.rating	=	'R'			THEN 	'from 21 up'
		END						AS 		expected_audience_age

FROM	rental r 																							-- Joining tables (rental, inventory, and film) to be able to find film title  and its rating.
INNER JOIN	inventory i 		ON		r.inventory_id 	=	i.inventory_id 
INNER JOIN 	film f 				ON		i.film_id 		=	f.film_id 

GROUP BY f.title, f.rating																					-- Grouping the results in order to find the number of rentals per each film
ORDER BY number_of_rentals DESC 																			-- seting ORDER...
LIMIT 5;																									-- ...and limits.


--Which actors/actresses didn't act for a longer period of time than others? 

WITH	actor_activity	AS																					-- created just a temporary "table" to list down all actors and years where they had their film released.
						(
						SELECT 	CONCAT(a.first_name,' ',last_name)	AS	actor_name,
								f.release_year						AS	active_years
						
						FROM actor a 
						INNER JOIN	film_actor fa 	ON	a.actor_id 	=	fa.actor_id 
						INNER JOIN	film f 			ON	fa.film_id 	=	f.film_id  
						
						ORDER BY CONCAT(a.first_name,' ',last_name) ASC, f.release_year ASC
						),
				
		table_years		AS 																					-- The table from above (actor_activity) is modified in this step. I wanted to have every possible pair of two  different years per each actor
						(
						SELECT 	a.actor_name,
								a.active_years	AS	movie_1,
								aa.actor_name	AS	actor_confirmation,										-- this column is actually redundant here, I just leave it for a check (confirmation for me)
								aa.active_years	AS	movie_2	
						
						FROM actor_activity a																 
						CROSS JOIN actor_activity aa														-- Self cross join let me gain every possible result (combination of every year from release column)	
						WHERE a.actor_name	=	aa.actor_name AND (aa.active_years-a.active_years >0)		-- I filter out the results – need only the pairs of years assigned to one actor (do not want to compare the release years of different actors) and I  need only the results where the second year is bigger that the firs one.
						),
		
		pair_of_years	AS 																					-- I modified the previous “table” again (table_years) and left only pairs consisting of movie_1 and the year of movie_2 which follows directly
						(						
						SELECT 	actor_name,
								movie_1,		
								MIN(movie_2)	AS 	next_movie
										
						FROM table_years	
						GROUP BY	actor_name, movie_1
						ORDER BY actor_name,movie_1
						)

-- At this point I have a table with actors’ name and pairs like:  film released year and released year of the next film which follows 

				
SELECT 	actor_name,																							-- Just chosen the actors and calculated the max difference between each pair of years
		MAX(next_movie-movie_1)	AS max_period
FROM pair_of_years
GROUP BY actor_name
ORDER BY MAX(next_movie-movie_1) DESC																		-- Set an order... 
LIMIT 5;																									--...and limit the outcome.







-- Top-3 most selling movie categories of all time and total dvd rental income for each category. Only consider dvd rental customers from the USA



WITH usa_customers  AS  (                                                                           -- usa_customers  retrievs customer_id for customers only from USA - it could be a subquery IN SECOND CTE but I prefer that way
                        SELECT customer_id 
                        FROM customer cus
                        INNER JOIN address a    ON  cus.address_id  =   a.address_id 
                        INNER JOIN city c       ON  a.city_id       =   c.city_id 
                        WHERE c.country_id =    (
                                                SELECT  country_id
                                                FROM    country c2
                                                WHERE TRIM(UPPER(c2.country)) ='UNITED STATES'
                                                )
                        ),
                                        
                        
    usa_rental      AS                                                                                  
                    (                                                                               -- shows rental_id ONLY FOR USA 
                    SELECT  r.rental_id
                    FROM rental r       
                    WHERE r.customer_id     IN  (SELECT * FROM usa_customers)
                    ),
                    
    rental_stat     AS                                                                              -- shows top 3 categories FOR USA only.
                    (
                    SELECT  c.category_id,
                            c.name,
                            COUNT(r.rental_id)  
                                                        
                    FROM usa_rental r
                    INNER JOIN  rental r2           ON  r.rental_id     =   r2.rental_id 
                    INNER JOIN  inventory i         ON  r2.inventory_id =   i.inventory_id 
                    INNER JOIN  film f              ON  i.film_id       =   f.film_id 
                    INNER JOIN  film_category fc    ON  f.film_id       =   fc.film_id 
                    INNER JOIN  category c          ON  fc.category_id  =   c.category_id 

                    GROUP BY c.category_id, c.name
                    ORDER BY COUNT(r.rental_id) DESC
                    LIMIT 3
                    )
                    
SELECT  c.category_id,                                                                              -- I chose  categories AND sum OF amount from paymant table
        c.name,
        SUM(p.amount)       AS sum_of_income
        

FROM payment p  
INNER JOIN  rental r            ON  p.rental_id     =   r.rental_id 
INNER JOIN  inventory i         ON  r.inventory_id  =   i.inventory_id 
INNER JOIN  film f              ON  i.film_id       =   f.film_id 
INNER JOIN  film_category fc    ON  f.film_id       =   fc.film_id 
INNER JOIN  category c          ON  fc.category_id  =   c.category_id 

WHERE   (c.category_id IN (SELECT rs.category_id FROM rental_stat rs)) AND                          -- Set condition that category has to be the same as from the rental stat table and rental_id must be the same as inusa_rental          
        (p.rental_id IN (SELECT ur.rental_id FROM usa_rental ur))

GROUP BY c.category_id, c.name
ORDER BY SUM(p.amount)


;


-- For each client, display a list of horrors that he had ever rented (in one column, separated by commas), and the amount of money that he paid for it
                                                                
                
SELECT      c.customer_id, 
            c.first_name, 
            c.last_name, 
            GROUP_CONCAT(DISTINCT f.title)  AS  rented_horror_movies,                                 
            SUM(p.amount) AS total_paid
FROM    customer c
INNER JOIN rental r     ON  c.customer_id   =   r.customer_id
INNER JOIN inventory i  ON  r.inventory_id  =   i.inventory_id
INNER JOIN film f       ON  i.film_id       =   f.film_id
INNER JOIN payment p    ON  r.rental_id     =   p.rental_id

WHERE f.film_id IN  (                                                                               -- took fil_id from a range created with sub query      
                    SELECT film_id FROM film_category                                               -- subquery to retrevie only film  ids marked as  "horror" category     
                    WHERE  category_id =
                                            (
                                            SELECT cat.category_id                                  -- one value outcome subquery -shows category_id FOR horrors
                                            FROM category  cat
                                            WHERE UPPER(cat.name) = 'HORROR'
                                            )
                    )
GROUP BY c.customer_id, c.first_name, c.last_name
ORDER BY c.customer_id



