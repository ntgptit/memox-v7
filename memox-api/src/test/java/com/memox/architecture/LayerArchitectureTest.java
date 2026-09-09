package com.memox.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static org.assertj.core.api.Assertions.assertThat;

import org.junit.jupiter.api.Test;

import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.core.importer.ClassFileImporter;
import com.tngtech.archunit.core.importer.ImportOption;
import com.tngtech.archunit.junit.AnalyzeClasses;
import com.tngtech.archunit.junit.ArchTest;
import com.tngtech.archunit.lang.ArchRule;

/**
 * The dependency directions between layers, enforced rather than described.
 *
 * <p>Transport is now {@code controller} and {@code dto} rather than the single {@code api}
 * package these rules were written against. A rule naming a package that no longer exists selects
 * nothing and passes — so a rename that did not bring the guard with it would leave three green
 * assertions guarding an empty set. {@link #everyGuardedPackageStillExists()} is what makes that
 * impossible to do quietly: it fails the moment a package named here stops matching any class.
 */
@AnalyzeClasses(packages = "com.memox", importOptions = ImportOption.DoNotIncludeTests.class)
class LayerArchitectureTest {

	private static final String TRANSPORT = "..controller..";
	private static final String CONTRACT = "..dto..";
	private static final String PERSISTENCE = "..persistence..";
	private static final String SERVICE = "..service..";
	private static final String ENTITY = "..entity..";

	@ArchTest
	static final ArchRule transportDoesNotReachPersistence = noClasses()
			.that().resideInAnyPackage(TRANSPORT, CONTRACT)
			.should().dependOnClassesThat()
			.resideInAPackage(PERSISTENCE);

	@ArchTest
	static final ArchRule servicesDoNotReachTransport = noClasses()
			.that().resideInAPackage(SERVICE)
			.should().dependOnClassesThat()
			.resideInAnyPackage(TRANSPORT, CONTRACT);

	@ArchTest
	static final ArchRule persistenceDoesNotReachTransport = noClasses()
			.that().resideInAPackage(PERSISTENCE)
			.should().dependOnClassesThat()
			.resideInAnyPackage(TRANSPORT, CONTRACT);

	/**
	 * The layout's own promise: an entity knows nothing about how it is served or stored.
	 *
	 * <p>New with the split. It was unstateable while entities, enums and exceptions shared one
	 * {@code domain} package with nothing to point at.
	 */
	@ArchTest
	static final ArchRule entitiesDependOnNoOuterLayer = noClasses()
			.that().resideInAPackage(ENTITY)
			.should().dependOnClassesThat()
			.resideInAnyPackage(TRANSPORT, CONTRACT, PERSISTENCE, SERVICE);

	@Test
	void architectureRulesAreDiscoveredByJUnit() {
		// ArchUnit executes the declared rules; this test keeps the class visible to JUnit discovery.
	}

	@Test
	void everyGuardedPackageStillExists() {
		final JavaClasses production = new ClassFileImporter()
				.withImportOption(ImportOption.Predefined.DO_NOT_INCLUDE_TESTS)
				.importPackages("com.memox");

		for (final String guarded : new String[] { TRANSPORT, CONTRACT, PERSISTENCE, SERVICE, ENTITY }) {
			assertThat(production.stream().anyMatch(type -> matches(type.getPackageName(), guarded)))
					.as("no class lives in %s, so every rule naming it passes vacuously — "
							+ "the package was renamed and this guard was not brought along", guarded)
					.isTrue();
		}
	}

	private static boolean matches(String packageName, String archUnitPattern) {
		final var fragment = archUnitPattern.replace("..", "");
		return packageName.contains("." + fragment + ".") || packageName.endsWith("." + fragment);
	}
}
