/**
* Name: ORYZAresults
* Based on the internal empty template. 
* Author: pc
* Tags: 
*/


model ORYZAresults

/* Insert your model definition here */

global {
	file plot_shp <- file("C:/Users/pc/Gama_Workspace/Field Experiment/includes/Shapefile/kiengiang.shp");
	string op_file <- "../includes/Results/2016/op2016.csv";
	string res_file <- "../includes/Results/2016/res2016.csv";
	
	map<int, list<float>> water_levels_cf;
	map<int, list<float>> water_levels_awd;
	list<float> time_steps;
	
	int current_time_step <- 0;
	int max_time_steps <- 100;
	float max_water_level <- 40;
	
	list<int> cf_plots <- [2, 4, 5];
	list<int> awd_plots <- [1, 3];
	
	list<float> cf_water_levels <- [
        10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 8.61,
        25.9, 16.8, 35.0, 21.7, 6.5, 22.8, 13.4, 32.7, 25.4, 11.7,
        30.5, 23.9, 13.1, 31.8, 26.1, 15.0, 33.5, 29.8, 20.5, 38.83,
        32.1, 24.6, 37.4, 31.7, 25.3, 36.9, 32.4, 27.1, 35.8, 30.2,
        24.1, 33.6, 28.7, 22.8, 31.4, 27.3, 20.9, 29.8, 25.6, 18.7,
        27.1, 23.4, 16.2, 24.8, 21.1, 13.9, 22.5, 18.8, 11.6, 20.2,
        16.5, 9.3, 17.9, 14.2, 7.0, 15.6, 12.0, 4.7, 13.3, 9.8,
        2.4, 11.0, 7.5, 0.1, 8.7, 5.2, 6.66, 4.3, 1.0, 3.6,
        0.7, 2.9, 0.4, 2.2, 0.1, 1.5, 0.8, 0.5, 0.2, 0.9,
        0.6, 0.3, 1.0, 0.7, 0.4, 0.1, 0.8, 0.5, 0.2, 0.0
    ];
    
    list<float> awd_water_levels <- [
        10.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 8.61,
        25.9, 16.8, 35.01, 21.7, 6.5, 22.8, 13.4, 32.7, 25.4, 11.7,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 12.81, 8.9, 4.2, 1.5, 0.8, 0.1, 2.4,
        1.7, 0.3, 1.8, 1.1, 0.4, 1.2, 0.5, 0.8, 0.1, 0.6,
        0.3, 0.0, 0.4, 0.1, 0.7, 0.0, 0.3, 0.6, 0.2, 0.0
    ];
		
	geometry shape <- envelope(plot_shp);
	
	init {
		create plot from: plot_shp with: [plot_id::int(read("PLOT_ID"))];
		
		
		matrix data <- matrix(csv_file(res_file).contents);
		write data.rows;
		write data.columns;
		
		water_levels_cf <- [];
		water_levels_awd <- [];
		time_steps <- [];
		
		int rerun_col <- 0;
		int time_col <- 1;
		int wl0_col <- 40;
		
		loop i from: 1 to: data.rows - 1{
			int rerun_set <- int(data[rerun_col], i);
			float time_val <- float(data[time_col], i);
			float wl0_val <- float(data[wl0_col], i);
			
			if (rerun_set = 1) {
				if (water_levels_cf contains_key int(time_val)){
					water_levels_cf[int(time_val)] << wl0_val;
				} else {
					water_levels_cf[int(time_val)] <- [wl0_val];
					if (rerun_set = 1 and !(time_steps contains time_val)) {
						time_steps << time_val;
					}
				}
			} else if (rerun_set = 2) {
				if (water_levels_awd contains_key int(time_val)) {
					water_levels_awd[int(time_val)] << wl0_val;
				} else {
					water_levels_awd[int(time_val)] <- [wl0_val];
				}
			}		
		}
		
		write water_levels_awd;
		max_time_steps <- length(time_steps);
		
		ask plot {
			if (cf_plots contains plot_id) {
				treatment <- "CF";
			} else if (awd_plots contains plot_id) {
				treatment <- "AWD";
				
			} else {
				treatment <- "None";
			}
		}
	}
	reflex update_water_levels when: current_time_step < max_time_steps {
		int time_key <- int(time_steps[current_time_step]);
		
		ask plot {
			if(treatment = "CF" and water_levels_cf contains_key time_key) {
				water_level <- mean(water_levels_cf[time_key]);
			} else if (treatment = "AWD" and water_levels_awd contains_key time_key) {
				water_level <- mean(water_levels_awd[time_key]);
			}
			
			water_level <- min([water_level, max_water_level]);
			water_level <- max([water_level, 0.0]);
		}
		current_time_step <- current_time_step + 1;
	} 
	reflex stop_simulation when: current_time_step >= max_time_steps {
		do pause;
	}
}

species plot {
	int plot_id;
	string treatment;
	float water_level <- 0.0;
	
	aspect default {
		float water_ratio <- water_level / max_water_level;
		int blue_intensity <- int(100 + (155 * water_ratio));
		int green_intensity <- int(100 + (100 * water_ratio));
		int red_intensity <- int(100 + (50 * water_ratio));
		
		rgb water_color <- rgb(red_intensity, green_intensity, blue_intensity);
		
		draw shape color: water_color border: #black;
		
		draw string(plot_id) color: #black size:3 at: location;
		draw string(treatment + ": " + water_level with_precision 1 + "mm")
			color: #black size: 2 at: {location.x, location.y - 5};
	}
}

experiment demo type:gui {
	output {
		display map type: 2d {
			species plot aspect: default;
		}
	}
}