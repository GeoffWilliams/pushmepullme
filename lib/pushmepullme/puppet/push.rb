module PushMePullMe
  module Puppet
    module Push

      def self.upload_file(baseurl, path)
        status = 0
        puts "upload #{path} to #{baseurl}"

        status
      end

      def self.upload_dir(baseurl, dir)
        status = 0
        puts "upload #{dir} to #{baseurl}"

        status
      end

    end
  end
end