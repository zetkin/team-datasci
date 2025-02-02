"""This script is downloading all the DESO datasets in SCB.

It starts by parsing a page with all the datasets that SCB has that have DESO data.
For each of those datasets, it extracts the path tags to the API of SCB.
For the paths, it uses the pyscbwrapper to download the data, parse them, and
store them as CSV files.

It does a decent job, but the queries that are created by pyscbwrapper for
the API are not good enough to query all the datasets. It is not clear why the
queries fail at this time.
"""

import json
from typing import List
import os
import pandas as pd
from pyscbwrapper import SCB
import re
import requests
from bs4 import BeautifulSoup

data_dir = "./scb_data"

# SCB page hosting a list of all datsets with DESO codes.
URL = "https://www.scb.se/hitta-statistik/regional-statistik-och-kartor/regionala-indelningar/deso---demografiska-statistikomraden/deso-tabellerna-i-ssd--information-och-instruktioner/"


# From the links, get the id tags
def extract_id_tags(link):
    try:
        index = link.index("START")
    except ValueError as e:
        print(e)

    path = link[index:]
    parts = path.split("/")
    id_tags = parts[0].split("__")[1:]
    dataset = parts[1]

    id_tags.append(dataset)
    return id_tags


def parse_response(scb_response, observations):
    columns = scb_response["columns"]
    data = scb_response["data"]
    keys = []
    values = []
    for i, column in enumerate(columns):
        if column["text"] not in observations:
            keys.append((i, column["text"]))
        else:
            values.append((len(values), column["text"]))
    assert len(columns) == (len(keys) + len(values))
    response_records = []
    for record in data:
        record_dict = {}
        for i, column_name in keys:
            record_dict[column_name] = record["key"][i]
        for i, column_name in values:
            record_dict[column_name] = record["values"][i]
        response_records.append(record_dict)
        assert len(record_dict) == len(columns)
    return response_records


# This overwrites the set_query of pyscbwrapper
# It adds the else statement, which is there
# to grab all the data for the variables
# that have not a set of values.
def set_query(scb, **kwargs):
    """Forms a query from input arguments."""
    scb.clear_query()
    response = scb.info()
    variables = response["variables"]
    for kwarg in kwargs:
        for var in variables:
            if var["text"].replace(" ", "") == kwarg:
                scb.query["query"].append(
                    {
                        "code": var["code"],
                        "selection": {
                            "filter": "item",
                            "values": [
                                var["values"][j]
                                for j in range(len(var["values"]))
                                if var["valueTexts"][j] in kwargs[kwarg]
                            ],
                        },
                    }
                )
            else:
                scb.query["query"].append(
                    {
                        "code": var["code"],
                        "selection": {"filter": "all", "values": ["*"]},
                    }
                )


if __name__ == "__main__":
    page = requests.get(URL)
    soupper = BeautifulSoup(page.content, "html.parser")

    # Extract all the links to the datasets
    all_links = soupper.find_all(
        href=re.compile("https://www.statistikdatabasen.scb.se/pxweb/sv/ssd/")
    )

    tree_paths = []
    for href in all_links:
        link = href.get("href")
        link_tags = extract_id_tags(link)
        tree_paths.append(link_tags)

    for path in tree_paths:
        scb = SCB("en", *path)
        variables = scb.get_variables()
        info = scb.info()

        title = info["title"]
        print(title)

        filters = [key for key in list(variables.keys()) if key != "observations"]
        observations = variables["observations"]

        # The years need to be set here as the query
        # needs some kind of dimension to filter on.
        # This dimension does not have to be the year,
        # it can be any of the other variables,
        # but it's the most obvious choice
        set_query(scb, year=["2022", "2021"])
        try:
            response = scb.get_data()
            parsed_response = parse_response(response, observations)
            response_df = pd.DataFrame(parsed_response)
            response_df.name = title
            response_df.to_csv(os.path.join(data_dir, f"{title}.csv"))
        except json.decoder.JSONDecodeError as e:
            print("\terror retrieving data for query:", scb.get_query())

        print()
