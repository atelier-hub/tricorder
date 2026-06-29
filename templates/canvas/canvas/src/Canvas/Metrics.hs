-- | Prometheus metric names used across the application.
module Canvas.Metrics
    ( dbMetricNames
    )
where

import Atelier.Effects.DB (DBReadMetricNames (..))


-- | Metric names recorded for database read operations.
dbMetricNames :: DBReadMetricNames
dbMetricNames =
    DBReadMetricNames
        { queries = "canvas_db_queries_total"
        , errors = "canvas_db_query_errors_total"
        , duration = "canvas_db_query_duration_seconds"
        }
