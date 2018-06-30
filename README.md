# Pushmepullme

Welcome to your new gem! In this directory, you'll find the files you need to be able to package up your Ruby library into a gem. Put your Ruby code in the file `lib/pushmepullme`. To experiment with that code, run `bin/console` for an interactive prompt.

TODO: Delete this and the text above, and describe your gem

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'pushmepullme'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install pushmepullme

## Usage

### Puppet Pull

Download modules from the puppet forge, verifying the MD5 sum of the downloaded file against the published checksum.

#### puppetfile

Download all the modules in `Puppetfile`

```shell
pushmepullme puppet pull --puppetfile Puppetfile
```

* Files will be downloaded to a directory `modules` in the current working directory
* Optionally specify `--outputdir` if files should go somewhere else
* Puppetfile modules from git are not supported
* Puppetfile modules must specify version

#### module

Download a module from the Puppet Forge by name

```shell
pushmepullme puppet pull --module puppetlabs-stdlib-4.20.0
```

* Files will be downloaded to a directory `modules` in the current working directory
* Optionally specify `--outputdir` if files should go somewhere else
* Must specify version

### Puppet Push

Upload modules to Artifactory.

Artifactory is smart enough to serve the correct file based on module metadata so "folders" are only for aesthetic purposes.
For your convenience we will create the folder structure for you.

If a file to be uploaded already exists, it will not be uploaded again. To force a re-upload you must delete the files 
from artifactory as an administrator. 


### File

Upload a single file to artifactory

```shell
pushmepullme puppet push --baseurl http://admin:admin@192.168.33.10:8081/artifactory/puppet-local --file modules/crayfishx-firewalld-3.4.0.tar.gz
```

* Embed your credentials in the `baseurl`
* Report success/fail with proxies

### Directory

Upload a whole directory of files

```shell
pushmepullme puppet push --baseurl http://admin:admin@192.168.33.10:8081/artifactory/puppet-local --dir modules
```

* All files matching glob `*.tar.gz` in the directory will be uploaded
* Already existing files will be skipped

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/[USERNAME]/pushmepullme.

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).
