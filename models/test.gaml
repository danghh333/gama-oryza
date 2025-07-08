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
	string res_file <- "../includes/Results/2017/res2017.csv";
	
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
        0.0, 3.3, 0.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0,
        9.5, 21.1, 3.9, 16.4, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 10.0,
        20.7, 2.8, 16.5, 28.7, 10.0, 20.1, 2.4, 15.8, 27.4, 7.4,
        17.5, 30.2, 12.8, 23.3, 4.6, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,0.0, 0.0, 0.0, 0.0
    ];
		
	geometry shape <- envelope(plot_shp);
	
	init {
		create plot from: plot_shp with: [plot_id::int(read("PLOT_ID"))];
		
		ask plot {
			if (cf_plots contains plot_id) {
				treatment <- "CF";
			} else if (awd_plots contains plot_id) {
				treatment <- "AWD";
			} else {
				water_level <- 0.0;
			}
		}	
	}
	
	reflex update_water_levels when: current_time_step < max_time_steps {
		ask plot {
			if (treatment = "CF") {
				water_level <- cf_water_levels[current_time_step];
			} else if (treatment = "AWD"){
				water_level <- awd_water_levels[current_time_step];
			} else {
				water_level <- 0.0;
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
	string treatment <- "None";
	float water_level <- 0.0;
	
	aspect simple {
		rgb plot_color <- (water_level > 0) ? 
			rgb(0, int(100 + water_level * 3), int(150 + water_level * 2)) :
			rgb(139, 119, 101);
		draw shape color: plot_color border: #black;
	}
	
	aspect default {
		rgb plot_color;
		if (water_level <= 0.0) {
			plot_color  <- rgb(139, 119, 101);
		} else {
			float water_ratio <- water_level / max_water_level;
			int blue_intensity <- int(255 - (water_ratio * 205));
			
			blue_intensity <- max([blue_intensity, 50]);
			blue_intensity <- min([blue_intensity, 255]);
			
			int green_component <- int(blue_intensity * 0.3);
			plot_color <- rgb(0, green_component, blue_intensity);
			}
		draw shape color: plot_color border: #black width: 2;
	}
}

experiment demo type:gui {
	output synchronized: true {
		display map type: 2d {
			species plot aspect: default;
		}
	}
}