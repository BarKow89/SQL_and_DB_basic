# SQL_and_DB_basic

In the repository, I used a PostgreSQL sample database for learning and practicing PostgreSQL. The DVD rental database represents the business processes of a DVD rental store. 
There are 15 tables in the DVD Rental database:
•	actor – stores actors data including first name and last name.
•	film – stores film data such as title, release year, length, rating, etc.
•	film_actor – stores the relationships between films and actors.
•	category – stores film’s categories data.
•	film_category- stores the relationships between films and categories.
•	store – contains the store data including manager staff and address.
•	inventory – stores inventory data.
•	rental – stores rental data.
•	payment – stores customer’s payments.
•	staff – stores staff data.
•	customer – stores customer data.
•	address – stores address data for staff and customers
•	city – stores city names.
•	country – stores country names.
•	language – stores language id and its description.

The repository contains files as follows:
1.	SQL_dvd_rental_ER_Diagram – represents the DB structure.
2.	SELECT – contains queries solving the topics: 
I.	All comedy movies released between 2000 and 2004, alphabetical
II.	Revenue of every rental store for year 2017 (columns: address and address2 – as one column, revenue)
III.	Top-3 actors by number of movies they took part in (columns: first_name, last_name, number_of_movies, sorted by number_of_movies in descending order)
IV.	Number of comedy, horror and action movies per year (columns: release_year, number_of_action_movies, number_of_horror_movies, number_of_comedy_movies), sorted by release year in descending order
V.	Which staff members made the highest revenue for each store and deserve a bonus for 2017 year?
VI.	Which 5 movies were rented more than others and what's expected audience age for those movies?
VII.	Which actors/actresses didn't act for a longer period of time than others? (Calculating the time difference between films)
VIII.	Top-3 most selling movie categories of all time and total dvd rental income for each category. Only consider dvd rental customers from the USA
IX.	For each client, display a list of horrors that he had ever rented (in one column, separated by commas), and the amount of money that he paid for it

3.	DML  – contains queries solving the topics: 
X.	Choose my top-3 favorite movies and add them to the 'film' table. Fill rental rates with 4.99, 9.99, and 19.99 and rental durations with 1, 2 and 3 weeks respectively
XI.	Add actors who play leading roles in my favorite movies to 'actor' and 'film_actor' tables (6 or more actors in total).
XII.	Add my favorite movies to any store's inventory.
XIII.	Alter any existing customer in the database who has at least 43 rental and 43 payment records. Change his/her personal data to yours (first name, last name, address, etc.). Do not perform any updates on 'address' table, as it can impact multiple records with the same address. Change customer's create_date value to current_date
XIV.	Remove any records related to me (as a customer) from all tables except 'Customer' and 'Inventory'
XV.	Rent my favorite movies from the store they are in and pay for them (add corresponding records to the database to represent this activity)
4.	Functions – contains queries solving the topics:
XVI.	Create a function that will return the most popular film for each country (where the country is an input parameter).
XVII.	Creation of a function that returns a list of films by part of the title in stock (for example, films with the word 'love' in the title). If a film with the title is out of stock, it returns a message: a movie with that title was not found
XVIII.	Creation of a function that reports all information for a particular client and timeframe
