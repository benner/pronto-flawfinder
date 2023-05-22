# frozen_string_literal: true

require 'pronto'
require 'shellwords'
require 'open3'

module Pronto
  # Main class for extracting flawfinder complains
  class Flawfinder < Runner
    CPP_FILE_EXTENSIONS = %w[c cpp h hpp].freeze

    def initialize(patches, commit = nil)
      super(patches, commit)
    end

    def executable
      'flawfinder'
    end

    def files
      return [] if @patches.nil?

      @files ||= @patches
                 .select { |patch| patch.additions.positive? }
                 .map(&:new_file_full_path)
                 .map(&:to_s)
                 .compact
    end

    def patch_line_for_offence(path, lineno)
      patch_node = @patches.find do |patch|
        patch.new_file_full_path.to_s == path
      end

      return if patch_node.nil?

      patch_node.added_lines.find do |patch_line|
        patch_line.new_lineno == lineno
      end
    end

    def run
      if files.any?
        messages(run_flawfinder)
      else
        []
      end
    end

    def run_flawfinder # rubocop:disable Metrics/MethodLength
      Dir.chdir(git_repo_path) do
        cpp_files = filter_cpp_files(files)
        files_to_lint = cpp_files.join(' ')
        extra = ENV.fetch('PRONTO_flawfinder_OPTS', nil)
        if files_to_lint.empty?
          []
        else
          cmd = "#{executable} #{extra} #{files_to_lint}"
          stdout, _stderr, _status = Open3.capture3(cmd)

          parse_output stdout
        end
      end
    end

    def cpp?(file)
      CPP_FILE_EXTENSIONS.select { |extension| file.end_with? ".#{extension}" }.any?
    end

    def filter_cpp_files(all_files)
      all_files.select { |file| cpp? file.to_s }
               .map { |file| file.to_s.shellescape }
    end

    def parse_output(executable_output)
      lines = executable_output.split("\n").map(&:chomp)

      result_begins_at = lines.index "FINAL RESULTS:"
      result_ends_at = lines.index "ANALYSIS SUMMARY:"

      return [] if result_ends_at.nil? or result_begins_at.nil?

      lines = lines[result_begins_at+2, result_ends_at - result_begins_at - 3]

      # "a.c:4:  [4] (format) snprintf:"
      lines = lines.slice_before(/^\S+:\d+:\s+\[\d\]/).map(&:join)

      lines.
        map { |line| parse_output_line(line) }
    end

    def parse_output_line(line)
      splits = line.strip.split(':')
      message = splits[2..].join(':').strip
      message = "flawfinder: #{message}"
      {
        file_path: splits[0],
        line_number: splits[1].to_i,
        column_number: 0,
        message:,
        level: violation_level(message)
      }
    end

    def violation_level(message)
        'warning'
    end

    def messages(complains)
      complains.map do |msg|
        patch_line = patch_line_for_offence(msg[:file_path],
                                            msg[:line_number])
        next if patch_line.nil?

        description = msg[:message]
        path = patch_line.patch.delta.new_file[:path]
        Message.new(path, patch_line, msg[:level].to_sym,
                    description, nil, self.class)
      end.compact
    end

    def git_repo_path
      @git_repo_path ||= Rugged::Repository.discover(File.expand_path(Dir.pwd))
                                           .workdir
    end
  end
end
