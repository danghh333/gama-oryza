/**
* Name: all
* Based on the internal empty template. 
* Author: pc
* Tags: 
*/


model all

/* Insert your model definition here */

global {
	file plot_shp <- file("../includes/Shapefile/kiengiang.shp");
	file res_file <- csv_file("../includes/Results/2017/res2017.csv", ",", true);
	
	map<int, list<float>> water_levels_cf;
	map<int, list<float>> water_levels_awd;
	
	list<float> time_values <- [];
	list<float> water_level_values <- [];
	list<float> irrigation_values <- [];

	list<string> headers <- [];
	list<float> time_steps;
	
	int current_time_step <- 0;
	int max_time_steps <- 100;
	float max_water_level <- 100.0;
	
	list<int> cf_plots <- [2,4,5];
	list<int> awd_plots <- [1, 3];
	
	list<float> cf_water_level_values <- [];
	list<float> awd_water_level_values <- [];
	list<float> cf_leaf_area_index_values <- [];
	list<float> awd_leaf_area_index_values <- [];
	float current_cf_LAI <- 0.0;
	float current_awd_LAI <- 0.0;
	
	float current_cf_water_level <- 0.0;
	float current_awd_water_level <- 0.0;
	float current_average_temperature <- 25.0;
	list<float> average_temp <- [];
	float current_time <- 0.0;
	
	geometry shape <- envelope(plot_shp);
	
	init{
		create plot from: plot_shp with: [plot_id::int(read("PLOT_ID"))];
		
		max_time_steps <- length(time_steps);
		
		ask plot {
			if (cf_plots contains plot_id) {
				treatment <- "CF";
			} else if (awd_plots contains plot_id) {
				treatment <- "AWD";
			} else {
				water_level <- 0.0;
			}
		}
		
		headers <- res_file.attributes;
		matrix<string> data <- matrix(res_file);
		
		int rerun_index <- headers index_of "RERUN_SET";
		int time_index <- headers index_of "TIME";
		int wl0_index <- headers index_of "WL0";
		int LAI_index <- headers index_of "LAI";
		int max_temp_index <- headers index_of "TMAX";
		int min_temp_index <- headers index_of "TMIN";
		
		list<float> cf_time_values <- [];
		list<float> awd_time_values <- [];
		
		
		loop i from: 0 to: data.rows - 1 {
			string rerun_value <- data[rerun_index, i];
			
			if (rerun_value = "1.0"){
				add float(data[time_index, i]) to: cf_time_values;
				add float(data[wl0_index, i]) to: cf_water_level_values;
				add (float(data[min_temp_index, i])+float(data[min_temp_index, i]))/2 to: average_temp;
				add float(data[LAI_index, i]) to: cf_leaf_area_index_values;
			}
			else if (rerun_value = "2.0"){
				add float(data[time_index, i]) to: awd_time_values;
				add float(data[wl0_index, i]) to: awd_water_level_values;
				add float(data[LAI_index, i]) to: awd_leaf_area_index_values;	
			}
		}
		
		water_levels_cf <- [];
		water_levels_awd <- [];
		time_steps <- [];
		
		loop i from: 0 to: length(cf_time_values) - 1 {
			int time_key <- int(cf_time_values[i]);
			float wl0_val <- cf_water_level_values[i];
			
			if (water_levels_cf contains_key time_key){
				water_levels_cf[time_key] << wl0_val;
			} else {
				water_levels_cf[time_key] <- [wl0_val];
				if (!(time_steps contains cf_time_values[i])) {
					time_steps << cf_time_values[i];
				}
			}
		}
		write cf_water_level_values;
		
		loop i from: 0 to: length(awd_time_values) - 1 {
			int time_key <- int(awd_time_values[i]);
			float wl0_val <- awd_water_level_values[i];
			
			if (water_levels_awd contains_key time_key){
				water_levels_awd[time_key] << wl0_val;
			} else {
				water_levels_awd[time_key] <- [wl0_val];
				if (!(time_steps contains awd_time_values[i])) {
					time_steps << awd_time_values[i];
				}
			}
		}
		
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
		current_time <- time_steps[current_time_step];
		
		current_average_temperature <- average_temp[current_time_step];
		
		current_awd_LAI <- awd_leaf_area_index_values[current_time_step];
		current_cf_LAI <- cf_leaf_area_index_values[current_time_step];
		
		if (water_levels_cf contains_key time_key) {
			current_cf_water_level <- mean(water_levels_cf[time_key]);
		}
		if (water_levels_awd contains_key time_key) {
			current_awd_water_level <- mean(water_levels_awd[time_key]);
		}
		
		ask plot {
			if (treatment = "CF" and water_levels_cf contains_key time_key) {
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
		rgb plot_color;
		if (water_level <= 0.0) {
			plot_color <- rgb(139, 119, 101);
		} else {
			float water_ratio <- water_level / max_water_level;
			int blue_intensity <- int(255 - (water_ratio * 205));
			
			blue_intensity <- max([blue_intensity, 50]);
			blue_intensity <- min([blue_intensity, 255]);
			
			int green_component <- int(blue_intensity*0.3);
			plot_color <- rgb(0, green_component, blue_intensity);
		}
		draw shape color: plot_color border: #black width: 2;
		draw string(plot_id) color: #white size:13 at: location;
		draw string(treatment + ": " + water_level with_precision 1 + "mm")
			color: #white size: 13 at: {location.x, location.y - 5};
	}
}



experiment demo type: gui {
	float minimum_cycle_duration <- 0.1#s;
	output synchronized: false{
	layout horizontal([0::5000,vertical([1::5000,2::5000])::5000]) editors: false toolbars: false;
		display map type: 2d {
			species plot aspect: default;
		}
		display "Water Level/Temperature" type: 2d{
			chart "" type:series background: #white y_label: "Water level" y2_label: "Temperature"{
				data "CF" value: current_cf_water_level color: #blue marker: false;
				data "AWD" value: current_awd_water_level color: #red marker: false;
				data "Avg. Temperature" value: current_average_temperature use_second_y_axis: true 
					color: #orange marker: false style: step;
			}
		}
		display "Leaf Area Index" type: 2d{
			chart "Leaf Area Index" type:series background: #white {
				data "CF" value: current_cf_LAI color: #blue marker: false;
				data "AWD" value: current_awd_LAI color: #red marker: false;
			}
		}
	}
}

experiment truc {
	
}





