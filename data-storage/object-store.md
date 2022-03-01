# Object store

two object store buckets are provided for storing arbitrary data.

-   `at-plural-sh-at-onplural-sh-kubeflow-pipelines` - this is a bucket located
    which is used to store pipeline artifacts (intermediate results, data which
    is passed from one pipeline step to another). Each user has a protected
    prefix only they can read & write. This prefix contains the workspace name.

    For a user with the workspace `nico-becker` the protected prefix within the
    pipelines bucket is `pipelines/nico-becker/`.

    While pipeline artifacts are automatically stored within this bucket, users
    can also explicitly write data to their prefixes. However, for safely
    storing raw data or important results, the use of the `opentgptx` bucket is
    encouraged.

-   `opengptx` - this is a general purpose bucket. All data that should be
    shared among platform users should be put here. This bucket resides in a
    separate cloud environment. Therefor, data in this bucket has a much lower
    risk of getting lost during platform maintenance. It is recommended to
    store important data in this bucket. Temporary files can safely be stored
    in the pipelines bucket described above.

    Users can check if they already have access to this bucket using the below
    code snippet.

    ```python
    import boto3


    client = boto3.client('s3')

    # list bucket
    client.list_objects_v2(
        Bucket='opengptx'
    )

    # upload data
    binary_data = b'Here we have some data'
    client.put_object(
        Body=binary_data,
        Bucket='opengptx',
        Key='hello.txt'
    )
    ```

    If the above snippet does not execute, please contact 
    <nico.becker@alexanderthamm.com>