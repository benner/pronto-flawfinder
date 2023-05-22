# frozen_string_literal: true

require 'spec_helper'

module Pronto
  # rubocop:disable Metrics/BlockLength
  describe Flawfinder do
    let(:flawfinder) { Flawfinder.new(patches) }
    let(:patches) { [] }

    describe '#executable' do
      subject(:executable) { flawfinder.executable }

      it 'is `flawfinder` by default' do
        expect(executable).to eql('flawfinder')
      end
    end

    describe 'parsing' do
      it 'filtering C/C++ files' do
        files = %w[
          test.py
          test.c
          test.txt
          test.cpp
          test.rb
          test.h
          test.hpp
        ]

        exp = flawfinder.filter_cpp_files(files)
        expect(exp).to eq(%w[test.c test.cpp test.h test.hpp])
      end

      it 'parses a linter output to a map' do
        # taken from https://dwheeler.com/flawfinder/correct-results.txt
        executable_output = <<~LINES
          Flawfinder version 2.0.19, (C) 2001-2019 David A. Wheeler.
          Number of rules (primarily dangerous function names) in C/C++ ruleset: 222
          Examining a.c

          FINAL RESULTS:

          a.c:4:  [4] (format) snprintf:
            If format strings can be influenced by an attacker, they can be exploited,
            and note that sprintf variations do not always 0-terminate (CWE-134). Use
            a constant for the format specification.
          a.c:5:  [1] (buffer) strlen:
            Does not handle strings that are not 0-terminated; if given one it may
            perform an over-read (it could cause a crash if unprotected) (CWE-126).

          ANALYSIS SUMMARY:

          Hits = 2
          Lines analyzed = 6 in approximately 0.00 seconds (1848 lines/second)
          Physical Source Lines of Code (SLOC) = 5
          Hits@level = [0]   0 [1]   1 [2]   0 [3]   0 [4]   1 [5]   0
          Hits@level+ = [0+]   2 [1+]   2 [2+]   1 [3+]   1 [4+]   1 [5+]   0
          Hits/KSLOC@level+ = [0+] 400 [1+] 400 [2+] 200 [3+] 200 [4+] 200 [5+]   0
          Minimum risk level = 1

          Not every hit is necessarily a security vulnerability.
          You can inhibit a report by adding a comment in this form:
          // flawfinder: ignore
          Make *sure* it's a false positive!
          You can use the option --neverignore to show these.

          There may be other security vulnerabilities; review your code!
          See 'Secure Programming HOWTO'
          (https://dwheeler.com/secure-programs) for more information.
        LINES

        act = flawfinder.parse_output(executable_output)

        exp = [
          {
            file_path: 'a.c',
            line_number: 4,
            column_number: 0,
            message: 'flawfinder: [4] (format) snprintf:  If format strings can be influenced by an attacker, they can be exploited,  and note that sprintf variations do not always 0-terminate (CWE-134). Use  a constant for the format specification.',
            level: 'warning'

          },
          {
            file_path: 'a.c',
            line_number: 5,
            column_number: 0,
            message: 'flawfinder: [1] (buffer) strlen:  Does not handle strings that are not 0-terminated; if given one it may  perform an over-read (it could cause a crash if unprotected) (CWE-126).',
            level: 'warning'
          }
        ]
        expect(act).to eq(exp)
      end
    end

    describe '#run' do
      around(:example) do |example|
        create_repository
        Dir.chdir(repository_dir) do
          example.run
        end
        delete_repository
      end

      let(:patches) { Pronto::Git::Repository.new(repository_dir).diff('master') }

      context 'patches are nil' do
        let(:patches) { nil }

        it 'returns an empty array' do
          expect(flawfinder.run).to eql([])
        end
      end

      context 'no patches' do
        let(:patches) { [] }

        it 'returns an empty array' do
          expect(flawfinder.run).to eql([])
        end
      end

      context 'with patch data' do
        before(:each) do
          function_use = <<-PASTFILE
          // nothing
          PASTFILE

          add_to_index('test.rst', function_use)
          create_commit
        end

        context 'with error in changed file' do
          before(:each) do
            create_branch('staging', checkout: true)

            updated_function_def = <<-NEWFILE
            void main() {
            gets();
            }
            NEWFILE

            add_to_index('bad.cpp', updated_function_def)

            create_commit
            ENV['PRONTO_FLAWFINDER_OPTS'] = ''
          end

          it 'returns correct error message' do
            run_output = flawfinder.run
            expect(run_output.count).to eql(1)
            expect(run_output[0].msg).to eql('flawfinder: [5] (buffer) gets:  Does not check for buffer overflows (CWE-120, CWE-20). Use fgets() instead.')
          end
        end
      end
    end
  end
  # rubocop:enable Metrics/BlockLength
end
