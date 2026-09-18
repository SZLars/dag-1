from pathlib import Path

import duckdb
import pandas as pd
import plotly.express as px
from dash import Dash, dcc, html


# Find database
PROJECT_ROOT = Path(__file__).resolve().parents[1]
DB_PATH = PROJECT_ROOT / "data" / "warehouse" / "taxi_20556.duckdb"


# Connect to DuckDB
con = duckdb.connect(str(DB_PATH), read_only=True)


# Get data
query = """
SELECT
    d.date_day AS pickup_date,
    COALESCE(z.Borough, 'Unknown') AS borough,
    COALESCE(z.Zone, 'Unknown') AS pickup_zone,
    a.trip_count,
    a.distance_sum,
    a.distance_count
FROM aggregate_trip_day_zone AS a

LEFT JOIN dim_date AS d
    ON a.pickup_date_key = d.date_key

LEFT JOIN dim_zone AS z
    ON a.pickup_zone_key = z.zone_key
"""

df = con.execute(query).fetchdf()

con.close()




total_trips = int(df["trip_count"].sum())

average_distance = (
    df["distance_sum"].sum()
    / df["distance_count"].sum()
)


daily = (
    df.groupby("pickup_date", as_index=False)
    ["trip_count"]
    .sum()
)

fig_daily = px.line(
    daily,
    x="pickup_date",
    y="trip_count",
    title="Trips per day",
    labels={
        "pickup_date": "Date",
        "trip_count": "Trips"
    }
)




borough = (
    df.groupby("borough", as_index=False)
    ["trip_count"]
    .sum()
    .sort_values("trip_count", ascending=False)
)

fig_borough = px.bar(
    borough,
    x="borough",
    y="trip_count",
    title="Trips by pickup borough",
    labels={
        "borough": "Borough",
        "trip_count": "Trips"
    }
)




zones = (
    df.groupby("pickup_zone", as_index=False)
    ["trip_count"]
    .sum()
    .sort_values("trip_count", ascending=False)
    .head(20)
)

fig_zones = px.bar(
    zones,
    x="pickup_zone",
    y="trip_count",
    title="Top 20 pickup zones",
    labels={
        "pickup_zone": "Pickup zone",
        "trip_count": "Trips"
    }
)




app = Dash(__name__)

app.layout = html.Div(
    [
        html.H1("NYC Yellow Taxi Data"),

        html.H2(
            f"Total trips: {total_trips:,}"
        ),

        html.H2(
            f"Average distance: {average_distance:.2f} miles"
        ),

        dcc.Graph(
            figure=fig_daily
        ),

        dcc.Graph(
            figure=fig_borough
        ),

        dcc.Graph(
            figure=fig_zones
        ),
    ],
    style={
        "maxWidth": "1200px",
        "margin": "auto",
        "fontFamily": "Arial"
    }
)


if __name__ == "__main__":
    app.run(debug=True)