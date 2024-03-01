# UNICEF_Database-Normalization

This project works with a raw, unstructured dataset comprising 2 million records. It utilizes SQL DDL and PL/SQL to effectively normalize and structure the data. Techniques include Insert, Update, Merge, Indexes, Procedures, and Views.

The raw data has only one unstructured table that looks like:
![1709308561437](https://github.com/yuwei-3206/UNICEF_Database-Normalization/assets/122844465/4acb6a50-bf8c-4821-a3e9-57e5bbc1cb37)

After designing the database, there is a fact table with 3 dimension tables:
![data](https://github.com/yuwei-3206/UNICEF_Database-Normalization/assets/122844465/65fa8c22-842a-4a8d-88ce-6fbb5061fc6f)


The fact table contains the fact indicators, making it easy to search for and retrieve data, while also improving database efficiency, reducing redundancy, and enhancing data integrity.

![1709308971671](https://github.com/yuwei-3206/UNICEF_Database-Normalization/assets/122844465/b3a58416-7445-479d-9e24-1952dd7d9a5e)
