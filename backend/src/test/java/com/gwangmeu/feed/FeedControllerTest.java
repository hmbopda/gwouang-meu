package com.gwangmeu.feed;

import com.gwangmeu.shared.BaseIntegrationTest;
import io.restassured.RestAssured;
import io.restassured.http.ContentType;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.boot.test.web.server.LocalServerPort;
import org.springframework.http.HttpStatus;

import static io.restassured.RestAssured.given;
import static org.hamcrest.Matchers.*;

class FeedControllerTest extends BaseIntegrationTest {

    @LocalServerPort
    int port;

    @BeforeEach
    void setUp() {
        RestAssured.port = port;
        RestAssured.basePath = "/api/v1/feed";
    }

    @Test
    void getPost_nonExistent_returns404() {
        given()
            .when().get("/00000000-0000-0000-0000-000000000000")
            .then()
            .statusCode(HttpStatus.NOT_FOUND.value())
            .contentType(ContentType.JSON)
            .body("success", is(false))
            .body("status", is(404));
    }

    @Test
    void getVillageFeed_returnsEmptyList() {
        given()
            .when().get("/village/00000000-0000-0000-0000-000000000000")
            .then()
            .statusCode(HttpStatus.OK.value())
            .body("success", is(true))
            .body("data", is(empty()));
    }

    @Test
    void createPost_withoutToken_returns401() {
        given()
            .contentType(ContentType.JSON)
            .body("{\"content\": \"Hello world\"}")
            .when().post()
            .then()
            .statusCode(HttpStatus.UNAUTHORIZED.value());
    }

    @Test
    void myFeed_withoutToken_returns401() {
        given()
            .when().get("/my-feed")
            .then()
            .statusCode(HttpStatus.UNAUTHORIZED.value());
    }
}
