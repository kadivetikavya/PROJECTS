package example.smallest.controllers;

import org.springframework.stereotype.Controller;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestMethod;
import org.springframework.web.bind.annotation.ResponseBody;

@Controller
public class WelcomeController {
	
	@RequestMapping(method = RequestMethod.GET, produces = {"text/html"})
	public @ResponseBody String helloWorld() {

		return "<p style=\"font-size:24px; font-weight:bold;\"> Enterprise CI/CD Pipeline with Security Controls Launched Successfully</p>";

	}
}
