import os

from typing import List

import pandas as pd
from pyscbwrapper import SCB

data_dir = 'data'

# Extract employment data
scb = SCB('en')
scb.go_down('AM', 'AM0210', 'AM0210G', 'ArRegDesoStatus')
data = scb.info()

variables = data['variables']
variable_dict = {var['code']: var for var in variables}
variable_keys = list(variable_dict.keys())
regions = variable_dict['Region']['valueTexts']

scb.set_query(region=regions,observations=['number of employed and unemployed (labour force)', 'number of unemployed'],  # Title of info in leaf node
          year=['2022'], age=['20-64 years']
)

response = scb.get_data()

# Parse Employment data and store to csv
response_data = response['data']
response_records = [
    {
        'deso': record['key'][0],
        'age': record['key'][1],
        'year': record['key'][2],
        'number of employed and unemployed (labour force)': record['values'][0],
        'number of unemployed': record['values'][1]
    }
    for record in response_data
]

response_df = pd.DataFrame(response_records)

response_df.to_csv(os.path.join(data_dir, 'scb_employment_per_age_year_deso.csv'))


# Extract education data
def get_scb_data(scb_api_path: List[str], lang='sv', **kwargs):
    scb = SCB(lang)
    scb.go_down(*scb_api_path)
    scb.set_query(**kwargs)
    return scb.get_data()

response = get_scb_data(['UF', 'UF0506', 'UF0506YDeso', 'UtbSUNBefDesoRegso'], år=['2022'],
                        utbildningsnivå=['förgymnasial utbildning',
                                         'gymnasial utbildning',
                                         'eftergymnasial utbildning, mindre än 3 år',
                                         'eftergymnasial utbildning, 3 år eller mer',
                                         'uppgift om utbildningsnivå saknas']
                         # tabellinnehåll=['Befolkning 25-64 år efter region, utbildningsnivå, år och tabellinnehåll']
)

# Parse education data and save to csv
response_data = response['data']
response_records = [
    {
        'deso': record['key'][0],
        'utbildningsnivå': record['key'][1],
        'year': record['key'][2],
        'Befolkning 25-64 år efter region, utbildningsnivå, år och tabellinnehåll': record['values'][0]
    }
    for record in response_data
]

final_df = pd.DataFrame(response_records)
final_df.to_csv(os.path.join(data_dir, 'scb_people_per_deso_education_year.csv'))
