# numb3rspipeline

numb3rspipeline is software for supporting the user in the selection of IoT infographics for manual data extraction.

The user provides a text file with URLs referencing IoT infographics.
The pipeline downloads the infographic and performs an OCR. As a result, it creates text files for each infographic containing the OCR text. All data transfer between the pipeline and the user takes place via _user-specific_ DropBox folders.

Finally, the user may search through the text files for specific key words of interest in this project. If the search hits these keywords, it also identifies the files for manual inspection and data extraction.

## Getting Started

### Install

tbd

**Updating from github**

Call a script with the following content.

```bash
cd "$HOME"/IoTNumb3rs && \
    git reset --hard HEAD && \
    git pull && \
    find . -type f -name '*.sh' | xargs chmod +x
```


### Run Pipeline

First, create a python virtualenv.
```bash
make venv
```

The pipeline interacts with Dropbox fetching and placing data in `<userdir>` on the Dropbox.
```bash
./numb3rspipeline.sh <dataroot dir> <dropbox userdir>
```

**Use in Production**

The following scripts call the pipeline and interact with [Slack](https://slack.com) notfiying users on the pipeline's processing. The testrun script calls the pipeline in production and will place the data into `/tmp/testdata` for the user `testuser`.
```bash
cd numb3rspipeline
./testrun.sh
```

The regular run in production for a specfic user.
```bash
./run4all.sh <dataroot dir> <dropbox userdir>
```

The regular run in production for the list of default users.
```bash
./run4all.sh <dataroot dir> 
```

### Run Pipeline as cronjob

Add the following `cron_numb3rspipeline.sh` into a user's home directory.

```bash
#!/bin/bash

#
# The numb3rspipeline cronjob
# will run this script
#

# the IoTNumb3rs directory
cd "$HOME"/IoTNumb3rs

# activate virtualenv
source venv/bin/activate

# here are the scripts
cd numb3rspipeline
# configure and fire up the pipeline
DATADIR="$HOME"/iotdata
mkdir -p "$DATADIR"
./run4all.sh "$DATADIR" >> "$HOME"/numb3rspipeline.log

# deactivate virtualenv
deactivate
```

Add the following line into a user's crontab via `crontab -e` to run the pipeline every 3 hours.
```
0 */3 * * * "$HOME"/cron_numb3rspipeline.sh >/dev/null 2>&1 
```


### Terms

* run: a single run of the pipeline. Within a run, the pipeline processes all given URLs referencing IoT infographics. 
* batch: all URLs referencing IoT infographics from a single run
* user folder: a _user-specific_ DropBox folder, e.g. named after the user
* OCR text: the extracted text as the result of OCR processing of the infographic

### Input

Users create a text file containing URLs referencing IoT infographics.
Afterwards, this file is placed into a user folder accessible for the pipeline.

Input data is provided as regular text file. 

**File name:** `url_list.txt`

**Input file data structure:**

* Each line contains a single URL starting with `http(s)`.
* Each line ends with a carriage return - '\n'

Format of `url_list.txt`: 
```
<URL starting with http(s)> \n
...
```

### Output

The numb3rspipeline stores the result in a folder indicating date and time as nomenclature.
Each run has its own result directory containing the batch results. The result directory is placed together with the `url_list.txt` file in the user folder. The `url_list.txt` file is deleted from its original place in the user folder making the numb3rspipeline essentially ready for the next run of a URL batch.

#### Result directory name: `yyyyMMdd-HHMM/`

Content of `yyyyMMdd-HHMM/`:
``` 
file1_<name of graphics file>
file2_<name of graphics file>
...
file<n>_<name of graphics file>

file1_<name of graphics file>.txt
file2_<name of graphics file>.txt
file<n>_<name of graphics file>.txt

url_filelist.csv
url_list.txt
```

#### Detailed Description of Pipeline Output 

`file<n>_<name of graphics file>` 

The original file name prefixed by `file<some integer>_`. This convention prohibits overwriting when URLs reference different resources, but with the same file name. The numb3rspipeline resolves this situation by prefixing. No action required by the user. 

`file<n>_<name of graphics file>.txt`

The extracted text as result of the OCR processing of the `file<n>_<name of graphics file>`. The file starts with a  header indicating the URL and processed file name. It consists of two text sections.
The first section contains the OCR text as a result of the OCR processing of the original image.
The OCR processes the image a second time, but this time the image is enhanced by a filter. The result is stored as a second text section divided by a separator. The entire format is shown below.

Format of `file<n>_<name of graphics file>.txt`:
```
##################################
Infographic URL: <URL from url_list.txt>
Infographic file: file<n>_<name of graphics file>
##################################

... OCR text of the original infographic image ... 

##################################

... OCR text of the enhanced infographic image ... 

``` 

`url_filelist.csv`

Contains provided URLs from `url_list.txt` and associates it with the corresponding file name downloaded by numb3rspipeline.

File format of `url_filelist.csv`
```
url;filename
<URL from url_list.txt>;file<n>_<name of graphics file>
...
```

## Contributing

The public [Trello board](https://trello.com/b/n18A4ThF) contains the current dev tasks.
If you like to contribute to the project, just submit a pull requests.

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/cdeck3r/IoTNumb3rs/tags).

## Authors

* Christian Decker - *Initial work*

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details


