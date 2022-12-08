
# Metadata Management

We realized everyone started creating metadata with different structure and on different locations without considering different aspects. That is why we want to collect best practices, technolgies and tools keeping our project needs in mind.
This document is about metadata management for the datasets (not for trainings, models, ...).

## In short


1. technical decision how to store metadata (pyton+json)
2. decision where to store metadata (subfolder or so)
3. content of metadata


## Example structure

```
s3://opengptx/datasources_ogptx/docs/v0.1.2/
    en/
        bundestag/
            metadata.json
            (metadata_biases.json)
            data/
```

## Example metadata 

```
{
  "train": {
    "word_count": {
      "de": {
        "bundestag": 880067683,
        "oscar": 40113103765,
        "paracrawl": 3198486559,
        "newspaper_iais": 2948433594,
        "wiki40b": 522202653,
        "opensubtitles": 181117003,
        "dta": 23213074,
        "one_million_posts": 4028219
      }
    },
    "en": {
      "pile": 50171390868
    }
  },
  "validation": {
    "word_count": {
      "de": {
        "bundestag": 224480959,
        "oscar": 10033553087,
        "paracrawl": 799902282,
        "newspaper_iais": 737217171,
        "wiki40b": 130612178,
        "opensubtitles": 45311523,
        "dta": 4511067,
        "one_million_posts": 994710
      }
    },
    "en": {
      "pile": 33475743843
    }
  }
}
```

## Example code

```

```





## Metadata tools

Hive...

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

### JSON vs. YAML:

Technically YAML is a superset of JSON. Which means (in theory at least), a YAML parser can understand JSON, but not necessarily the other way around.

A `+` means a pro for YAML, A `-` means a pro for JSON:
`+`visually easier to look at / easy for a human to read
+YAML has the ability to reference other items within a YAML file using "anchors."
+YAML is more robust about embedding other serialization formats such as JSON or XML within a YAML file.
-JSON is often faster and is probably still interoperable with more systems
+Duplicate keys, which are potentially valid JSON, are definitely invalid YAML.
+Python programmers are generally big fans of YAML, because of the use of indentation, rather than bracketed syntax, to indicate levels. 
+YAML uses space indentation, which is familiar territory for Python developers.
-JSON is much faster to serialize and deserialize because of significantly less features than YAML to check for, which enables smaller and lighter code to process JSON.
-YAML actually requires more characters than JSON
+The lack of comments in JSON is, in practice, a real pain.
-YAML has widespread support, but is less ubiquitous than JSON, and each parser implements a different subset. Hence YAML files are less interoperable than you might think.

It is relatively easy to convert one of those formats into the other. Be forewarned though, you will lose comments when converting a YAML document to JSON.

JSON is much faster, at the expense of some readability, and features such as comments: https://stackoverflow.com/a/62843005

Most of the time people will not use those extra features and the main difference is that YAML uses indentation whilst JSON uses brackets.

JSON is the winner for performance (if relevant) and interoperability. YAML is better for human-maintained files.

There are a plethora of parsers that work very well in all languages for both YAML and JSON.
Python programmers tend towards preferring YAML, JavaScript programmers towards JSON.

**Hence the file format JSON is the best option in our context to store metadata.**

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