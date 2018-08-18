# Contributing 

## Issues
If there are any issues, feel free to create an issue on the GitHub repository issue page.

## Setting Up
To clone the repository and install dependencies:

```bash
git clone https://github.com/chanzuckerberg/safe_type.git
cd ./safe_type
bundle
```

In order to run all tests from within the directory:

```ruby
rake spec
```

## Contribution Guidelines
1.  Make commits that are logically well isolated and have descriptive commit messages.
 
2.  Make sure that there are tests in the [spec](./spec) directory for the code you wrote.

3.  Make sure that changes to public methods or interfaces are documented in this README.

4.  Run tests and address any errors.

5.  Open a pull request with a descriptive message that describes the change, the need, and verification that the change is tested.
