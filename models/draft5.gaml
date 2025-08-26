model draft

global {
    file plot_shp <- file("../includes/Shapefile/kiengiang.shp");
    geometry shape <- envelope(plot_shp);
    
    // Daily output from ORYZA for both CF and AWD
    map<string, file> data_files <- [
        "CF"::csv_file("../includes/Results/CF_s1/cf_res.csv"),
        "AWD"::csv_file("../includes/Results/AWD_s1/awd_res.csv")
    ];
    
    string REGIME_CF <- "CF";
    string REGIME_AWD <- "AWD";
    list<string> REGIMES <- [REGIME_CF, REGIME_AWD];
    
    list<string> ORYZA_VARIABLES <- ["water_level", "lai", "soc", "son", "nh3", "n2o", "co2rel"];
    map<string, string> COLUMN_MAPPING <- [
        "water_level"::"WL0",
        "lai"::"LAI",
        "soc"::"SOC",
        "son"::"SON",
        "nh3"::"NH3",
        "n2o"::"N2O",
        "co2rel"::"CO2RELEASED"
    ];
    
    // Season tracking
    int current_year <- 2015;
    string current_season <- "Winter-Spring 2015-2016";
    int current_season_index <- 1;
    
    // Cast ORYZA output [regime][variable][rerun_set][doy] -> value
    map<string, map<string, map<int, map<int, float>>>> all_data;
    
    // Current simulation data: [regime][variable][doy] -> value
    map<string, map<string, map<int, float>>> current_data;
    
    // Temperature data (shared between regimes)
    map<int, map<int, float>> temperature_data;
    map<int, float> current_temperature_data;
    
    // Current display values: [regime][variable] -> value
    map<string, map<string, float>> current_values;
    float current_temperature <- 25.0;
    
    // Time management
    list<int> current_doy_steps;
    int current_doy_index <- 0;
    int max_doy_steps;
    int current_doy <- 1;
    
    // Visualization
    float max_water_level <- 100.0;
    
    // Plot assignments
    map<string, list<int>> regime_plots <- [
        REGIME_CF::[2,4,5],
        REGIME_AWD::[1,3]
    ];
    
    // Season-Year mapping
    map<int, pair<int,string>> rerun_to_season_year;
    
    init {
        create plot from: plot_shp with: [plot_id::int(read("PLOT_ID"))];
        
        do initialize_data_structures;
        do create_season_year_mapping;
        do process_all_files;
        do set_current_season(1);
        do assign_plot_regimes;
    }
    
    action initialize_data_structures {
        // Initialize nested maps for all regimes and variables
        loop regime over: REGIMES {
            all_data[regime] <- [];
            current_data[regime] <- [];
            current_values[regime] <- [];
            
            loop variable over: ORYZA_VARIABLES {
                all_data[regime][variable] <- [];
                current_data[regime][variable] <- [];
                current_values[regime][variable] <- 0.0;
            }
        }
    }
    
	action create_season_year_mapping {
		rerun_to_season_year[1] <- 2015::"Winter-Spring 2015-2016";
		rerun_to_season_year[2] <- 2016::"Summer-Autumn 2016";
		rerun_to_season_year[3] <- 2016::"Winter-Spring 2016-2017";
		rerun_to_season_year[4] <- 2017::"Summer-Autumn 2017";
		rerun_to_season_year[5] <- 2017::"Winter-Spring 2017-2018";
		rerun_to_season_year[6] <- 2018::"Summer-Autumn 2018";
		rerun_to_season_year[7] <- 2018::"Winter-Spring 2018-2019";
		rerun_to_season_year[8] <- 2019::"Summer-Autumn 2019";
		rerun_to_season_year[9] <- 2019::"Winter-Spring 2019-2020";
		rerun_to_season_year[10] <- 2020::"Summer-Autumn 2020";
	}
    
    // 
    action process_all_files {
        loop regime over: REGIMES {
            if (data_files contains_key regime) {
                do process_regime_file(data_files[regime], regime);
            }
        }
    }
    
    action process_regime_file(file regime_file, string regime) {
        list<string> headers <- regime_file.attributes;
        matrix<string> data <- matrix(regime_file);
        
        write "Processing " + regime + " file with " + data.rows + " rows";
        
        // Get column indices
        map<string, int> column_indices;
        column_indices["rerun"] <- headers index_of "RERUN_SET";
        column_indices["doy"] <- headers index_of "DOY";
        column_indices["tmax"] <- headers index_of "TMAX";
        column_indices["tmin"] <- headers index_of "TMIN";
        
        // Get indices for all parameters
        loop variable over: ORYZA_VARIABLES {
            string column_name <- COLUMN_MAPPING[variable];
            column_indices[variable] <- headers index_of column_name;
        }
        
        // Process each row
        loop i from: 0 to: data.rows - 1 {
            int rerun_set <- int(data[column_indices["rerun"], i]);
            int doy_val <- int(data[column_indices["doy"], i]);
            
            // Store variable values
            loop variable over: ORYZA_VARIABLES {
                float value <- float(data[column_indices[variable], i]);
                do store_value(regime, variable, rerun_set, doy_val, value);
            }
            
            // Store temperature (only from CF file)
            if (regime = REGIME_CF) {
                float tmax <- float(data[column_indices["tmax"], i]);
                float tmin <- float(data[column_indices["tmin"], i]);
                float avg_temp <- (tmax + tmin) / 2;
                
                if (!(temperature_data contains_key rerun_set)) {
                    temperature_data[rerun_set] <- [];
                }
                temperature_data[rerun_set][doy_val] <- avg_temp;
            }
        }
        
        write "Completed processing " + regime + " file";
    }
    
    action store_value(string regime, string variable, int rerun_set, int doy, float value) {
        // Initialize nested maps if needed
        if (!(all_data[regime][variable] contains_key rerun_set)) {
            all_data[regime][variable][rerun_set] <- [];
        }
        all_data[regime][variable][rerun_set][doy] <- value;
    }
    
    action set_current_season(int season_index) {
        current_season_index <- season_index;
        
        if (rerun_to_season_year contains_key season_index) {
            pair<int,string> season_year <- rerun_to_season_year[season_index];
            current_year <- season_year.key;
            current_season <- season_year.value;
            
            // Load data for current season
            loop regime over: REGIMES {
                loop variable over: ORYZA_VARIABLES {
                    if (all_data[regime][variable] contains_key season_index) {
                        current_data[regime][variable] <- all_data[regime][variable][season_index];
                    } else {
                        current_data[regime][variable] <- [];
                    }
                }
            }
            
            // Load temperature data
            if (temperature_data contains_key season_index) {
                current_temperature_data <- temperature_data[season_index];
            } else {
                current_temperature_data <- [];
            }
            
            // Get DOY steps (use first treatment's first parameter as reference)
            current_doy_steps <- current_data[REGIME_CF]["water_level"].keys;
            current_doy_steps <- current_doy_steps sort_by each;
            max_doy_steps <- length(current_doy_steps);
            current_doy_index <- 0;
            
            write "Loaded " + current_season + " (Season " + season_index + ") with " + max_doy_steps + " days";
        }
    }
    
    action assign_plot_regimes {
        ask plot {
            regime <- "None";
            water_level <- 0.0;
            
            loop regime_name over: regime_plots.keys {
                if (regime_plots[regime_name] contains plot_id) {
                    regime <- regime_name;
                    break;
                }
            }
        }
    }
    
    reflex update_simulation when: current_doy_index < max_doy_steps {
        current_doy <- current_doy_steps[current_doy_index];
        
        // Update all current values
        loop regime over: REGIMES {
            loop variable over: ORYZA_VARIABLES {
                if (current_data[regime][variable] contains_key current_doy) {
                    current_values[regime][variable] <- current_data[regime][variable][current_doy];
                }
            }
        }
        
        // Update temperature
        if (current_temperature_data contains_key current_doy) {
            current_temperature <- current_temperature_data[current_doy];
        }
        
        // Update plots
        ask plot {
            if (regime != "None") {
                water_level <- current_values[regime]["water_level"];
                water_level <- min([water_level, max_water_level]);
                water_level <- max([water_level, 0.0]);
            }
        }
        
        current_doy_index <- current_doy_index + 1;
    }
 
    reflex next_season when: current_doy_index >= max_doy_steps {
        int next_season <- current_season_index + 1;
        if (next_season <= 10) {
            do set_current_season(next_season);
        } else {
            write "Simulation completed all seasons 2015-2020";
            do pause;
        }
    }
    
    // Helper function to get current value for a treatment and parameter
    float get_current_value(string regime, string variable) {
        if (current_values contains_key regime and 
            current_values[regime] contains_key variable) {
            return current_values[regime][variable];
        }
        return 0.0;
    }
    
    /* 
    // Navigation actions
    action go_to_season(int season_index) {
        if (season_index >= 1 and season_index <= 10) {
            do set_current_season(season_index);
        }
    }
    
    action go_to_previous_season {
        if (current_season_index > 1) {
            do set_current_season(current_season_index - 1);
        }
    }
    
    action go_to_next_season {
        if (current_season_index < 10) {
            do set_current_season(current_season_index + 1);
        }
    }
    * 
    */
}

species plot {
    int plot_id;
    string regime;
    float water_level <- 0.0;
    
    aspect default {
        rgb plot_color <- calculate_water_color();
        draw shape color: plot_color border: #black width: 2;
        draw string(plot_id) color: #white size: 13 at: location;
        draw string(regime + ": " + water_level with_precision 1 + "mm")
            color: #white size: 13 at: {location.x, location.y - 5};
    }
    
    rgb calculate_water_color {
        if (water_level <= 0.0) {
            return rgb(139, 119, 101);
        } else {
            float water_ratio <- water_level / max_water_level;
            int blue_intensity <- int(255 - (water_ratio * 205));
            blue_intensity <- max([50, min([255, blue_intensity])]);
            int green_component <- int(blue_intensity * 0.3);
            return rgb(0, green_component, blue_intensity);
        }
    }
}

experiment run1 type: gui {
    float minimum_cycle_duration <- 0.1#s;
    
    output synchronized: false {
        layout horizontal([0::5000, vertical([1::5000, 2::5000])::5000]) 
            editors: false toolbars: false;
        
        display map type: 2d {
            species plot aspect: default;
        }
        
        display "Water Level/Temperature" type: 2d {
            chart "" type: series background: #white 
                y_label: "Water level" y2_label: "Temperature" {
                data "CF" value: get_current_value(REGIME_CF, "water_level") 
                    color: #blue marker: false;
                data "AWD" value: get_current_value(REGIME_AWD, "water_level") 
                    color: #red marker: false;
                data "Average Temperature" value: current_temperature 
                    use_second_y_axis: true color: #orange marker: false style: step;
            }
        }
        
        display "Leaf Area Index" type: 2d {
            chart "Leaf Area Index" type: series background: #white {
                data "CF" value: get_current_value(REGIME_CF, "lai") 
                    color: #blue marker: false;
                data "AWD" value: get_current_value(REGIME_AWD, "lai") 
                    color: #red marker: false;
            }
        }
    }
}

// Emission
experiment run2 type: gui {
    float minimum_cycle_duration <- 0.1#s;
    
    output synchronized: false {
        layout horizontal([0::5000, vertical([1::5000, 2::5000])::5000]) 
            editors: false toolbars: false;
        
        display "N2O" type: 2d {
            chart "" type: series background: #white 
                y_label: "Nitrous Oxide Level (per ha)" {
                data "CF_N2O" value: get_current_value(REGIME_CF, "n2o") 
                    color: #blue marker: false;
                data "AWD_N2O" value: get_current_value(REGIME_AWD, "n2o") 
                    color: #red marker: false;
            }
        }
        
        display "SOC" type: 2d {
            chart "" type: series background: #white 
                y_label: "Soil Organic Carbon Level (per ha)" {
                data "CF_SOC" value: get_current_value(REGIME_CF, "soc") 
                    color: #blue marker: false;
                data "AWD_SOC" value: get_current_value(REGIME_AWD, "soc") 
                    color: #red marker: false;
            }
        }
        
        display "CO2 Released" type: 2d {
            chart "" type: series background: #white 
                y_label: "CO2 Released (per ha)" {
                data "CF_CO2rel" value: get_current_value(REGIME_CF, "co2rel") 
                    color: #blue marker: false;
                data "AWD_CO2rel" value: get_current_value(REGIME_AWD, "co2rel") 
                    color: #red marker: false;
            }
        }
    }
}