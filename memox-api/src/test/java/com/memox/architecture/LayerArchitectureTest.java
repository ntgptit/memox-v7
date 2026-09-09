package com.memox.architecture;

import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.classes;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noClasses;
import static com.tngtech.archunit.lang.syntax.ArchRuleDefinition.noMethods;
import static org.assertj.core.api.Assertions.assertThat;

import org.apache.ibatis.annotations.Delete;
import org.apache.ibatis.annotations.Insert;
import org.apache.ibatis.annotations.Select;
import org.apache.ibatis.annotations.Update;
import org.junit.jupiter.api.Test;

import com.tngtech.archunit.base.DescribedPredicate;
import com.tngtech.archunit.core.domain.JavaClass;
import com.tngtech.archunit.core.domain.JavaClasses;
import com.tngtech.archunit.library.dependencies.SlicesRuleDefinition;
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

	private static final String ROOT = "com.memox";
	private static final String COMMON = "com.memox.common..";

	/**
	 * Every package a feature is allowed to put a class in.
	 *
	 * <p>{@code *} matches exactly one segment, so these are per-feature: {@code com.memox.tag.entity}
	 * matches, {@code com.memox.tag.domain} does not, and neither does a package nested one level
	 * deeper than the layout allows.
	 */
	private static final String[] ALLOWED_FEATURE_PACKAGES = {
			"com.memox.*.controller",
			"com.memox.*.dto.request",
			"com.memox.*.dto.response",
			"com.memox.*.entity",
			"com.memox.*.enums",
			"com.memox.*.exception",
			"com.memox.*.persistence",
			"com.memox.*.service",
	};

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

	/**
	 * The guard the other four could not give: no class may sit outside the layout at all.
	 *
	 * <p>Every rule above is open-world. Each one names packages and constrains what those packages
	 * may depend on, so a class in a package none of them names is not caught breaking a rule — it
	 * is never selected by one. {@code com.memox.tag.domain.Tag} would compile, pass CI and ship
	 * with no architecture signal whatsoever, which is exactly the shape the Phase 2 plan's own
	 * (pre-rename) file lists would have produced.
	 *
	 * <p>This is the closed-world half: state the packages that exist, and fail on anything else.
	 * It is deliberately the rule that needs editing when a legitimately new shape appears — that
	 * edit is the review conversation about whether the shape should exist.
	 */
	@ArchTest
	static final ArchRule everyClassLivesInTheDeclaredLayout = classes()
			.that().resideOutsideOfPackage(ROOT)
			.and().resideOutsideOfPackage(COMMON)
			.should().resideInAnyPackage(ALLOWED_FEATURE_PACKAGES);

	/**
	 * The shared kernel stays shared: {@code common} may not know any feature.
	 *
	 * <p>Written as "depends on com.memox but not on com.memox.common" rather than by listing deck
	 * and card, so a feature added tomorrow is covered without anyone remembering to add it here —
	 * the failure mode this whole class exists to prevent.
	 */
	@ArchTest
	static final ArchRule commonKnowsNoFeature = noClasses()
			.that().resideInAPackage(COMMON)
			.should().dependOnClassesThat(
					JavaClass.Predicates.resideInAPackage("com.memox..")
							.and(JavaClass.Predicates.resideOutsideOfPackage(COMMON)));

	/**
	 * SQL lives in {@code *_mapper.xml}, and no annotation may smuggle it back into Java.
	 *
	 * <p>Live before Phase 2 writes its first mapper rather than after, which is the only ordering
	 * that helps: a rule added at the end of a module's construction can only report what is
	 * already there, and by then removing an annotation is a refactor rather than a keystroke.
	 *
	 * <p>It says {@code noMethods}, not {@code noClasses}. MyBatis puts {@code @Select} on the
	 * method; a class-level check compiles, reads correctly and can never fire — which is what the
	 * version drafted for Phase 2 did, and what injecting a fault into it revealed.
	 */
	@ArchTest
	static final ArchRule sqlLivesOnlyInMapperXml = noMethods()
			.that().areDeclaredInClassesThat().resideInAPackage(PERSISTENCE)
			.should().beAnnotatedWith(Select.class)
			.orShould().beAnnotatedWith(Update.class)
			.orShould().beAnnotatedWith(Insert.class)
			.orShould().beAnnotatedWith(Delete.class);

	/**
	 * A feature may use another feature's published surface, and nothing else of it.
	 *
	 * <p>Two halves, and the second is the one that took a failing run to get right.
	 *
	 * <p><strong>Only a service may reach across.</strong> The source of every allowance below is
	 * {@code ..service..}, so a controller, a DTO or a mapper that names another feature's type is
	 * refused. What stays forbidden for everyone is the part that matters: another feature's
	 * {@code persistence}. {@code CardService} asking {@code DeckService} whether a deck accepts
	 * cards is collaboration; {@code CardService} reading {@code DeckMapper} is the same question
	 * answered by reaching around the feature that owns it, leaving two places that know how a deck
	 * is stored and one of them maintained.
	 *
	 * <p><strong>Calling a service means touching the types on its signature.</strong> Allowing
	 * only service-to-service is not expressible: {@code DeckService.prepareCardCreation} returns a
	 * {@code DeckSchedulerState} and hands back a {@code SchedulerType}, so {@code CardService}
	 * necessarily depends on {@code deck.entity} and {@code deck.enums} — which is what the first
	 * version of this rule failed on. Entities and enums are therefore part of the published
	 * surface. That is bounded rather than open: a card service still cannot <em>fetch</em> a deck,
	 * because fetching needs the mapper it may not see.
	 *
	 * <p>Anything not listed is refused, so widening the coupling means editing this rule — which
	 * is the review conversation about whether it should widen.
	 */
	@ArchTest
	static final ArchRule featuresDoNotReachEachOthersInternals = SlicesRuleDefinition.slices()
			.matching("com.memox.(*)..")
			.namingSlices("$1")
			.should().notDependOnEachOther()
			.ignoreDependency(
					JavaClass.Predicates.resideInAPackage(SERVICE),
					JavaClass.Predicates.resideInAnyPackage(SERVICE, ENTITY, "..enums..", "..exception.."))
			.ignoreDependency(
					DescribedPredicate.alwaysTrue(),
					JavaClass.Predicates.resideInAPackage(COMMON));

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
