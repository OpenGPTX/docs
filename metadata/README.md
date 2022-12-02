
# Metadata Management

We realized everyone started creating metadata with different structure and on different locations without considering different aspects. That is why we want to collect best practices, technolgies and tools keeping our project needs in mind.
This document is about metadata management for the datasets (not for trainings, models, ...).

## In short




## Example structure

```

```

## Example code

```

```





## Metadata tools



## File format

In this section you can find a brief overview about the following file formats: XML, CSV, JSON, Parquet and Avro.

|                         | CSV                    | JSON                   | Parquet | Avro |
| ----------------------- | ---------------------- | ---------------------- | ------- | ---- |
| Columnar                | No                     | No                     | Yes     | No   |
| Compressible            | Yes, when uncompressed | Yes, when uncompressed | Yes     | Yes  |
| Splittable              | Yes                    | Yes                    | Yes     | Yes  |
| Human Readable          | Yes                    | Yes                    | No      | No   |
| Nestable                | No                     | Yes                    | Yes     | Yes  |
| Complex Data Structures | No                     | Yes                    | Yes     | Yes  |
| Schema evolution        | No                     | No                     | Yes     | Yes  |

The main disadvantage of JSON is the bad performance in comparison to the other file formats but this is not really critical when storing metadata because the size is relatively small. Whereas the strenghts of JSON are the clearly defined schemes, the ability to store complex data and being human readable.

JSON and XML belong relatively close together in this comparison but XML is older, the files are larger and not that common nowadays anymore.

Hence the file format JSON is the best option in our context to store metadata.

## Programming language

Since we heavily rely on Spark as a distributed compute engine to process the datasets, at a first glance it looks like it should be also used for metadata management. But it has a lot disadvanatges by design. Writing JSON with spark by using `dataframe.write.json("metadata.json")` actually writes JSONL and not JSON which makes it harder to read the file with other languages. There are ways (like [here](https://stackoverflow.com/questions/58238563/write-spark-dataframe-as-array-of-json-pyspark) and [here](https://stackoverflow.com/questions/48503419/spark-dataframe-serialized-as-invalid-json)) to workaround this but it is quite complex and not that easy to understand.

However, we are already close to Python due to using PySpark to execute Spark. Python can easily process JSON and can easily upload files onto S3.

Hence pure Python is the best option in our context to read and write metadata from/to JSON files. Of course other programming languages are also capable doing so.

## Data Mesh

In this section are some important principles and thoughts about "Data Mesh". This topic is huge but it brings some of the important points related to our context of metadata.

### Principle

- Principle of Domain Ownership - Decentralize the ownership of analytical data to business domains closest to the data.
- Principle of Data as a Product: discoverable, addressable, understandable
- Principle of the Self-Serve Data Platform: Abstract data management complexity and reduce the cognitive load of domain teams in managing the end-to-end life cycle of their data products.
- Principle of Federated Computational Governance: The governance execution model heavily relies on codifying and automating the policies at a fine-grained level, for every data product, via the platform services.

### Enable Autonomous Teams to Get Value from Data

Metadata should be next to the data itself and should bringt a good overview about the content of the data.

### Introduce feedback loops

Based on new learnings and experience (feedback from data users and data owners), the metdadata management can be improved and extended. E.g. we can add more metdadata or we can improve the code to generate the metdata.