require "etc"

module Rack
  class DirectoryTemplate
    module Util
      def self.stat(path)
        entry = {}

        stat = ::File.lstat(path)    
        [:size, :mode, :mtime, :atime, :ctime].each do |field|
          entry[field] = stat.send(field)
        end

        entry[:type] = stat.ftype
        # Windows has none of this
        user = Etc.getpwuid(stat.uid)
        entry[:user] = user ? user.name : nil
        group = Etc.getgrgid(stat.gid)
        entry[:group] = group ? group.name : nil

        entry
      end
    end
  end
end
