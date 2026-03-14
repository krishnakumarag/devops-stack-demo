package com.devops.demo;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.HashMap;
import java.util.Map;

@RestController
public class HelloController {

    // Simple greeting - change this message to trigger a new pipeline run
    private static final String VERSION = "v1.0";

    @GetMapping("/")
    public Map<String, String> hello() {
        Map<String, String> response = new HashMap<>();
        response.put("message", "Hello from DevOps Stack Demo!");
        response.put("version", VERSION);
        response.put("status", "running");
        return response;
    }

    @GetMapping("/info")
    public Map<String, String> info() {
        Map<String, String> response = new HashMap<>();
        response.put("app", "devops-stack-demo");
        response.put("version", VERSION);
        response.put("stack", "Java + Docker + Jenkins + Ansible + Azure");
        return response;
    }
}
