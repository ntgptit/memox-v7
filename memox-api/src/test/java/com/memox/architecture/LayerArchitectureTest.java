package com.memox.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;

import org.junit.jupiter.api.Test;

import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

@AnalyzeClasses(packages = "com.memox", importOptions = ImportOption.DoNotIncludeTests.class)
class LayerArchitectureTest {

	@ArchTest
	static final ArchRule apiDoesNotReachPersistence = noClasses()
			.that().resideInAPackage("..api..")
			.should().dependOnClassesThat()
			.resideInAnyPackage("..repository..", "..persistence..", "..service.impl..");

	@ArchTest
	static final ArchRule servicesDoNotReachApi = noClasses()
			.that().resideInAPackage("..service..")
			.should().dependOnClassesThat()
			.resideInAPackage("..api..");

	@Test
	void architectureRulesAreDiscoveredByJUnit() {
		// ArchUnit executes the declared rules; this test keeps the class visible to JUnit discovery.
	}
}
