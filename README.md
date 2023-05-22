# Pronto runner for flawfinder

Pronto runner for [flawfinder](https://dwheeler.com/flawfinder/), command-line
program that examines C/C++ source code and reports possible security
weaknesses.

[What is Pronto?](https://github.com/prontolabs/pronto)

## Usage

* `gem install pronto-flawfinder`
* `pronto run`
* `PRONTO_FLAWFINDER_OPTS="--minlevel 3" pronto run` for passing CLI options
  to `flawfinder`

## Contribution Guidelines

### Installation

`git clone` this repo and `cd pronto-flawfinder`

Ruby

```sh
rbenv install 3.1.0 # or newer
rbenv global 3.1.0 # or make it project specific
gem install bundle
bundle install
```

Make your changes

```sh
git checkout -b <new_feature>
# make your changes
bundle exec rspec
gem build pronto-flawfinder.gemspec
gem install pronto-flawfinder-<current_version>.gem
pronto run --unstaged
```

## Changelog

0.1.0 Initial public version.
