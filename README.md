# US Baby Name Analysis

## Project Overview:

This project was inspired by the Guided Project Baby Trend Name Analysis, provided by Maven Analytics. The main objective is analysing trends in baby name popularity based on US social security data from 1980-2009, tracking changes, comparing popularity across decades and regions, and exploring unique names.

## Data Model:

The schema used is quite simple, with a fact table cointaining the amount of babies born with each name by State (including DC), birth Gender and Year, and a single fact table associating each State to a designated US Region.

After some initial exploration, two problems were uncovered in the regions fact table: the New Hampshire (NH) state was registered as "New England", instead of "New_England", and Michigan (MI) is missing from the Region column. While the inconsistencies could easily be addressed during analysis by writing a CTE correction every time the regions table was used, the best practice would be to inform the relevant people as to ensure data integrity. As such, since we're also acting as the database admin, a baby_names_regions_fix.sql was deployed to UPDATE and INSERT the necessary information.

## Analysis:

After the initial exploratory analysis mentioned above, our focus was to answer the questions proposed by the brief, and, since we had no means to contact our internal client to enquire about how they intend to use or present the data, we used this opportunity to explore different output structres for the same data, namely ordinary tables vs pivot tables/matrix.

On another note, most queries in this project require creating name popularity ranks, to track variation over time and across regions. From the 3 main ranking windows functions applicable in this instance, ROW_NUMBER(), RANK() and DENSE_RANK(), we opted to use RANK() as it respects both ties and gaps. Since ROW_NUMBER() breaks ties in an arbitrary way, it can lead to inconsistent results when evaluating lower ranks, with many ties. DENSE_RANK() not respecting ties can cause a considerable rank shrinkage and misleading results.

Now, let us explore a few results for each specific objetive:

- **Objective 1:** Track changes in name popularity, exploring how the most popular names have changed over time.

The overall most popular girl name is Jessica, and boy name is Michael. While Michael continues to be a top 3 until 2009, Jessica starts falling out of favour in 1998.

As for names with biggest jumps in popularity between the first and last years, we get very different results if we evaluate by number of births or by rank variation. In the former, we get names that were already     commonly used getting more popular, while the later has names that used to be very niche climbing thousands of ranks.

 **Objective 2:** Compare popularity across decades, finding the top 3 names for each birth gender by year and decade.

For this objective, we developed outputs organized as both ordinary tables and pivot tables/matrix.


- **Objective 3:** Compare popularity across regions, finding the top 3 names for each birth gender by region.

We got the total number of babies born by region for the the entire period, and then by year.


- **Objective 4:** Explore unique names in the dataset, exploring the shortest and long names, and the state with highest percent of babies named "Chris".

The shortest names had only 2 characters, with Ty being the most popular name, while the longest names had 15 characters, with the most popular being Franciscojavier, a two word name that was originally concatenated in the table.

Finally, we found that Louisiana (LA) was the State with highest percentage of babies named "Chris" in the period.
