package com.memox;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.ConfigurationPropertiesScan;

@SpringBootApplication
@ConfigurationPropertiesScan
public class MemoxApiApplication {

	public static void main(String[] args) {
		SpringApplication.run(MemoxApiApplication.class, args);
	}

}
