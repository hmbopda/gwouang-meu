package com.gwangmeu.village;

import com.gwangmeu.shared.BaseIntegrationTest;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

class VillageControllerTest extends BaseIntegrationTest {

    @LocalServerPort
    int port;

    @BeforeEach
    void setUp() {
        RestAssured.port = port;
        RestAssured.basePath = "/api/v1/villages";
    }

    @Test
    void getById_nonExistent_returns404() {
        given()
            .when().get("/00000000-0000-0000-0000-000000000000")
            .then()
            .statusCode(HttpStatus.NOT_FOUND.value())
            .contentType(ContentType.JSON)
            .body("success", is(false))
            .body("status", is(404));
    }

    @Test
    void byCountry_returnsEmptyList_whenNoVillages() {
        given()
            .when().get("/country/CMR")
            .then()
            .statusCode(HttpStatus.OK.value())
            .body("success", is(true))
            .body("data", is(empty()));
    }

    @Test
    void search_returnsEmptyList_whenNoMatch() {
        given()
            .queryParam("q", "nonexistentvillage12345")
            .when().get("/search")
            .then()
            .statusCode(HttpStatus.OK.value())
            .body("success", is(true))
            .body("data", is(empty()));
    }

    @Test
    void createVillage_withoutToken_returns401() {
        given()
            .contentType(ContentType.JSON)
            .body("{\"name\": \"Bafia\", \"country\": \"CMR\"}")
            .when().post()
            .then()
            .statusCode(HttpStatus.UNAUTHORIZED.value());
    }
}
