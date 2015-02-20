require 'spec_helper'

describe SCSSLint::Reporter::CheckStyleReporter do
  subject { SCSSLint::Reporter::CheckStyleReporter.new(lints) }

  describe '#report_lints' do
    let(:xml) { Nokogiri::XML(subject.report_lints) }

    shared_examples_for 'XML document' do
      it 'has an encoding of UTF-8' do
        xml.encoding.should == 'utf-8'
      end

      it 'has an XML version of 1.0' do
        xml.version.should == '1.0'
      end

      it 'contains a <checkstyle> root element' do
        xml.root.name.should == 'checkstyle'
      end
    end

    context 'when there are no lints' do
      let(:lints) { [] }

      it_should_behave_like 'XML document'
    end

    context 'when there are lints' do
      let(:filenames)    { ['f1.scss', 'f2.scss', 'f1.scss'] }
      # Include invalid XML characters in the third description to validate
      # that escaping happens for preventing broken XML output
      let(:descriptions) { ['lint 1', 'lint 2', 'lint 3 " \' < & >'] }
      let(:severities)   { [:warning] * 3 }

      let(:locations)    do
        [
          SCSSLint::Location.new(5,  2, 3),
          SCSSLint::Location.new(7,  6, 2),
          SCSSLint::Location.new(9, 10, 1)
        ]
      end

      let(:lints) do
        filenames.each_with_index.map do |filename, index|
          SCSSLint::Lint.new(nil, filename, locations[index],
                             descriptions[index], severities[index])
        end
      end

      it_should_behave_like 'XML document'

      it 'contains an <error> node for each lint' do
        xml.xpath('//error').count.should == 3
      end

      it 'contains a <file> node for each file' do
        xml.xpath('//file').map { |node| node[:name] }
          .should =~ filenames.uniq
      end

      it 'contains <error> nodes grouped by <file>' do
        xml.xpath('//file').map do |file_node|
          file_node.xpath('./error').count
        end.should =~ [1, 2]
      end

      it 'marks each issue with a line number' do
        xml.xpath('//error[@line]').map { |node| node[:line] }
          .should =~ locations.map { |location| location.line.to_s }
      end

      it 'marks each issue with a column number' do
        xml.xpath('//error[@column]').map { |node| node[:column] }
          .should =~ locations.map { |location| location.column.to_s }
      end

      it 'marks each issue with a length' do
        xml.xpath('//error[@length]').map { |node| node[:length] }
          .should =~ locations.map { |location| location.length.to_s }
      end

      it 'marks each issue with a message containing the lint description' do
        xml.xpath('//error[@message]').map { |node| node[:message] }
          .should =~ descriptions
      end

      context 'when lints are warnings' do
        it 'marks each issue with a severity of "warning"' do
          xml.xpath("//error[@severity='warning']").count == 3
        end
      end

      context 'when lints are errors' do
        let(:severities) { [:error] * 3 }

        it 'marks each issue with a severity of "error"' do
          xml.xpath("//error[@severity='error']").count == 3
        end
      end
    end
  end
end
