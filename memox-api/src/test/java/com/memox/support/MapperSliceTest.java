package com.memox.support;

import java.lang.annotation.Documented;
import java.lang.annotation.ElementType;
import java.lang.annotation.Inherited;
import java.lang.annotation.Retention;
import java.lang.annotation.RetentionPolicy;
import java.lang.annotation.Target;

import org.mybatis.spring.boot.test.autoconfigure.MybatisTest;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase;
import org.springframework.boot.test.autoconfigure.jdbc.AutoConfigureTestDatabase.Replace;
import org.springframework.context.annotation.Import;
import org.springframework.test.context.ActiveProfiles;

/**
 * The slice a mapper test runs in: MyBatis, Flyway and a real PostgreSQL, and nothing else.
 *
 * <p>{@link PostgresIntegrationTest} boots the whole application — controllers, services, MockMvc —
 * because the tests that extend it exercise the whole application. A mapper test does not: it asks
 * whether a statement in {@code *_mapper.xml} produces valid SQL and whether the result map binds
 * each column to the right field. Everything above {@code persistence} is scenery, and booting it
 * makes the failure message name a layer that had nothing to do with the fault.
 *
 * <p><strong>{@code replace = NONE} is the load-bearing attribute.</strong> {@code @MybatisTest}
 * carries {@code @AutoConfigureTestDatabase} with its default of {@code Replace.ANY}, which swaps
 * the configured {@code DataSource} for an embedded one. That would point this tier at a database
 * that is not PostgreSQL, and the whole reason a mapper test exists is that the SQL is executed by
 * the engine production uses.
 *
 * <p>Removing it was fault-injected rather than assumed: with {@code Replace.ANY} the context fails
 * to start with <em>"Failed to replace DataSource with an embedded database for tests. If you want
 * an embedded database please put a supported one on the classpath or tune the replace attribute of
 * &#64;AutoConfigureTestDatabase"</em> — no embedded driver is on the classpath, and the message
 * names the attribute. So this is a mistake that cannot be made silently; the note is here to
 * explain why the attribute is present, not to warn about a quiet failure.
 *
 * <p>Both backend configurations are imported for the same reason {@link PostgresIntegrationTest}
 * imports both: exactly one activates, chosen by {@code memox.test.database}, and importing them
 * from one place keeps every test in this tier on a single context cache key.
 *
 * <p><strong>This tier is transactional and rolls back.</strong> {@code @MybatisTest} is
 * meta-annotated {@code @Transactional}, so each test method gets a transaction that is rolled back
 * when it ends. Fixtures loaded with {@code @Sql} roll back with it, which is why this tier needs no
 * equivalent of {@code MemoxTestDataReset} — and why an {@code @Sql} script here may delete rows it
 * did not create without touching what another test committed.
 */
@Target(ElementType.TYPE)
@Retention(RetentionPolicy.RUNTIME)
@Documented
@Inherited
@ActiveProfiles("test")
@MybatisTest
@AutoConfigureTestDatabase(replace = Replace.NONE)
@Import({ PostgresTestcontainersConfiguration.class, LocalPostgresConfiguration.class })
public @interface MapperSliceTest {
}
