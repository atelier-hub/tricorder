{
  title = "GHC Performance";
  tags = [
    "ghc"
    "performance"
  ];
  timezone = "browser";
  editable = false;
  schemaVersion = 16;
  version = 0;
  refresh = "5s";
  uid = "ghc-performance";

  panels = [
    # Memory Usage Row
    {
      id = 100;
      title = "Memory Usage";
      type = "row";
      gridPos = {
        x = 0;
        y = 0;
        w = 24;
        h = 1;
      };
      collapsed = false;
    }
    {
      id = 1;
      title = "Heap Memory";
      type = "graph";
      description = "Current and peak live heap size. Shows memory actively used by the application.";
      gridPos = {
        x = 0;
        y = 1;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_gcdetails_live_bytes";
          refId = "A";
          legendFormat = "current live heap";
        }
        {
          expr = "ghc_max_live_bytes";
          refId = "B";
          legendFormat = "peak live heap";
        }
      ];
      yaxes = [
        {
          format = "bytes";
          label = "Bytes";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }
    {
      id = 2;
      title = "Total Memory In Use";
      type = "graph";
      description = "Total memory in use by the RTS including heap, stacks, and metadata.";
      gridPos = {
        x = 12;
        y = 1;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_gcdetails_mem_in_use_bytes";
          refId = "A";
          legendFormat = "current mem in use";
        }
        {
          expr = "ghc_max_mem_in_use_bytes";
          refId = "B";
          legendFormat = "peak mem in use";
        }
      ];
      yaxes = [
        {
          format = "bytes";
          label = "Bytes";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }
    {
      id = 3;
      title = "Large Objects";
      type = "graph";
      description = "Memory used by large objects (objects too large for regular heap blocks).";
      gridPos = {
        x = 0;
        y = 9;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_gcdetails_large_objects_bytes";
          refId = "A";
          legendFormat = "current large objects";
        }
        {
          expr = "ghc_max_large_objects_bytes";
          refId = "B";
          legendFormat = "peak large objects";
        }
      ];
      yaxes = [
        {
          format = "bytes";
          label = "Bytes";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }
    {
      id = 4;
      title = "Memory Slop";
      type = "graph";
      description = "Wasted memory due to fragmentation and padding.";
      gridPos = {
        x = 12;
        y = 9;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_gcdetails_slop_bytes";
          refId = "A";
          legendFormat = "current slop";
        }
        {
          expr = "ghc_max_slop_bytes";
          refId = "B";
          legendFormat = "peak slop";
        }
      ];
      yaxes = [
        {
          format = "bytes";
          label = "Bytes";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }

    # Garbage Collection Row
    {
      id = 101;
      title = "Garbage Collection";
      type = "row";
      gridPos = {
        x = 0;
        y = 17;
        w = 24;
        h = 1;
      };
      collapsed = false;
    }
    {
      id = 5;
      title = "GC Time";
      type = "graph";
      description = "Percentage of time spent in garbage collection. Shows GC CPU time and wall clock time.";
      gridPos = {
        x = 0;
        y = 18;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "rate(ghc_gc_cpu_seconds_total[5m])";
          refId = "A";
          legendFormat = "gc cpu time";
        }
        {
          expr = "rate(ghc_gc_elapsed_seconds_total[5m])";
          refId = "B";
          legendFormat = "gc wall time";
        }
      ];
      yaxes = [
        {
          format = "percentunit";
          label = "Time %";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }
    {
      id = 6;
      title = "Total GCs";
      type = "stat";
      description = "Total number of garbage collections since start.";
      gridPos = {
        x = 12;
        y = 18;
        w = 6;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_gcs_total";
          refId = "A";
        }
      ];
      options = {
        textMode = "value_and_name";
        colorMode = "none";
      };
      fieldConfig = {
        defaults = {
          unit = "short";
        };
      };
    }
    {
      id = 18;
      title = "Major GCs";
      type = "stat";
      description = "Total number of major garbage collections since start.";
      gridPos = {
        x = 18;
        y = 18;
        w = 6;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_major_gcs_total";
          refId = "A";
        }
      ];
      options = {
        textMode = "value_and_name";
        colorMode = "none";
      };
      fieldConfig = {
        defaults = {
          unit = "short";
        };
      };
    }
    {
      id = 7;
      title = "GC Rate";
      type = "graph";
      description = "Rate of garbage collections per second.";
      gridPos = {
        x = 0;
        y = 26;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "rate(ghc_gcs_total[5m])";
          refId = "A";
          legendFormat = "gc rate";
        }
        {
          expr = "rate(ghc_major_gcs_total[5m])";
          refId = "B";
          legendFormat = "major gc rate";
        }
      ];
      yaxes = [
        {
          format = "ops";
          label = "GCs/sec";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }
    {
      id = 8;
      title = "GC Details";
      type = "stat";
      description = "Current GC generation and thread count.";
      gridPos = {
        x = 12;
        y = 26;
        w = 6;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_gcdetails_gen";
          refId = "A";
        }
      ];
      options = {
        textMode = "value_and_name";
        colorMode = "none";
      };
    }
    {
      id = 9;
      title = "GC Threads";
      type = "stat";
      description = "Number of threads used for garbage collection.";
      gridPos = {
        x = 18;
        y = 26;
        w = 6;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_gcdetails_threads";
          refId = "A";
        }
      ];
      options = {
        textMode = "value_and_name";
        colorMode = "none";
      };
    }

    # Allocation & Copying Row
    {
      id = 102;
      title = "Allocation & Copying";
      type = "row";
      gridPos = {
        x = 0;
        y = 34;
        w = 24;
        h = 1;
      };
      collapsed = false;
    }
    {
      id = 10;
      title = "Allocation Rate";
      type = "graph";
      description = "Rate of memory allocation in bytes per second.";
      gridPos = {
        x = 0;
        y = 35;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "rate(ghc_allocated_bytes_total[5m])";
          refId = "A";
          legendFormat = "allocation rate";
        }
      ];
      yaxes = [
        {
          format = "Bps";
          label = "Bytes/sec";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }
    {
      id = 11;
      title = "Total Allocated";
      type = "stat";
      description = "Total bytes allocated since start.";
      gridPos = {
        x = 12;
        y = 35;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_allocated_bytes_total";
          refId = "A";
        }
      ];
      options = {
        textMode = "value_and_name";
        colorMode = "none";
        graphMode = "none";
      };
      fieldConfig = {
        defaults = {
          unit = "bytes";
        };
      };
    }
    {
      id = 12;
      title = "GC Copying Rate";
      type = "graph";
      description = "Rate at which GC copies live data between generations.";
      gridPos = {
        x = 0;
        y = 43;
        w = 24;
        h = 8;
      };
      targets = [
        {
          expr = "rate(ghc_copied_bytes_total[5m])";
          refId = "A";
          legendFormat = "copy rate";
        }
      ];
      yaxes = [
        {
          format = "Bps";
          label = "Bytes/sec";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }

    # Application Time Row
    {
      id = 103;
      title = "Application (Mutator) Time";
      type = "row";
      gridPos = {
        x = 0;
        y = 51;
        w = 24;
        h = 1;
      };
      collapsed = false;
    }
    {
      id = 14;
      title = "Mutator Time";
      type = "graph";
      description = "Percentage of time spent in application code (not GC).";
      gridPos = {
        x = 0;
        y = 52;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "rate(ghc_mutator_cpu_seconds_total[5m])";
          refId = "A";
          legendFormat = "mutator cpu time";
        }
        {
          expr = "rate(ghc_mutator_elapsed_seconds_total[5m])";
          refId = "B";
          legendFormat = "mutator wall time";
        }
      ];
      yaxes = [
        {
          format = "percentunit";
          label = "Time %";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }
    {
      id = 15;
      title = "Mutator vs GC Time";
      type = "graph";
      description = "Comparison of time spent in application code vs garbage collection.";
      gridPos = {
        x = 12;
        y = 52;
        w = 12;
        h = 8;
      };
      targets = [
        {
          expr = "rate(ghc_mutator_cpu_seconds_total[5m])";
          refId = "A";
          legendFormat = "mutator cpu";
        }
        {
          expr = "rate(ghc_gc_cpu_seconds_total[5m])";
          refId = "B";
          legendFormat = "gc cpu";
        }
      ];
      yaxes = [
        {
          format = "percentunit";
          label = "Time %";
          show = true;
        }
        {
          format = "none";
          show = false;
        }
      ];
    }

    # Total Runtime Row
    {
      id = 105;
      title = "Total Runtime";
      type = "row";
      gridPos = {
        x = 0;
        y = 60;
        w = 24;
        h = 1;
      };
      collapsed = false;
    }
    {
      id = 16;
      title = "Uptime";
      type = "stat";
      description = "Total wall clock time since application start.";
      gridPos = {
        x = 0;
        y = 61;
        w = 8;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_elapsed_seconds_total";
          refId = "A";
        }
      ];
      options = {
        textMode = "value_and_name";
        colorMode = "none";
        graphMode = "none";
      };
      fieldConfig = {
        defaults = {
          unit = "s";
        };
      };
    }
    {
      id = 17;
      title = "Total CPU Time";
      type = "stat";
      description = "Total CPU time consumed by the application since start.";
      gridPos = {
        x = 8;
        y = 61;
        w = 8;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_cpu_seconds_total";
          refId = "A";
        }
      ];
      options = {
        textMode = "value_and_name";
        colorMode = "none";
        graphMode = "none";
      };
      fieldConfig = {
        defaults = {
          unit = "s";
        };
      };
    }
    {
      id = 19;
      title = "CPU Efficiency";
      type = "gauge";
      description = "Ratio of CPU time to wall time (higher is better, max 1.0 for single-threaded).";
      gridPos = {
        x = 16;
        y = 61;
        w = 8;
        h = 8;
      };
      targets = [
        {
          expr = "ghc_cpu_seconds_total / ghc_elapsed_seconds_total";
          refId = "A";
        }
      ];
      options = {
        showThresholdLabels = false;
        showThresholdMarkers = true;
      };
      fieldConfig = {
        defaults = {
          unit = "percentunit";
          min = 0;
          max = 1;
          thresholds = {
            mode = "absolute";
            steps = [
              {
                value = 0;
                color = "red";
              }
              {
                value = 0.5;
                color = "yellow";
              }
              {
                value = 0.8;
                color = "green";
              }
            ];
          };
        };
      };
    }
  ];
}
