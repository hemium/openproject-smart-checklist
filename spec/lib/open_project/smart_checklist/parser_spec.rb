# frozen_string_literal: true

require "spec_helper"
require "open_project/smart_checklist/parser"

RSpec.describe OpenProject::SmartChecklist::Parser do
  describe ".parse" do
    it "parses canonical checkbox statuses" do
      items = described_class.parse(<<~TEXT)
        - [ ] todo item
        - [x] done item
        - [X] also done
        - [~] in progress item
        - [-] skipped item
      TEXT

      expect(items.pluck(:status)).to eq %i[todo done done in_progress skipped]
      expect(items.pluck(:text)).to eq ["todo item", "done item", "also done", "in progress item", "skipped item"]
    end

    it "parses Jira shorthand statuses" do
      items = described_class.parse(<<~TEXT)
        - todo item
        + done item
        ~ in progress item
        x skipped item
      TEXT

      expect(items.pluck(:status)).to eq %i[todo done in_progress skipped]
    end

    it "prefers the canonical bracket form over shorthand" do
      items = described_class.parse("- [x] a")

      expect(items.first).to include(text: "a", status: :done)
    end

    it "parses headers" do
      items = described_class.parse(<<~TEXT)
        # Section one
        ## Subsection
        ### Subsubsection
        - [ ] item
      TEXT

      expect(items.map { |i| i[:type] }).to eq %i[header header header item]
      expect(items.first[:text]).to eq "Section one"
    end

    it "attaches notes to the previous item" do
      items = described_class.parse(<<~TEXT)
        - [ ] item one
        > a note
        > another note
        - [ ] item two
      TEXT

      expect(items[0][:notes]).to eq ["a note", "another note"]
      expect(items[1][:notes]).to eq []
    end

    it "ignores notes appearing before any item" do
      items = described_class.parse(<<~TEXT)
        > orphan note
        - [ ] item
      TEXT

      expect(items.size).to eq 1
      expect(items.first[:notes]).to eq []
    end

    it "treats any other non-blank line as a todo item" do
      items = described_class.parse("just some text")

      expect(items.first).to include(type: :item, text: "just some text", status: :todo)
    end

    it "ignores blank lines and trims whitespace" do
      items = described_class.parse("\n  - [ ]   spaced   \n\n")

      expect(items.size).to eq 1
      expect(items.first[:text]).to eq "spaced"
    end

    it "returns an empty array for nil and empty text" do
      expect(described_class.parse(nil)).to eq []
      expect(described_class.parse("")).to eq []
    end
  end

  describe ".progress" do
    it "counts items by status and computes percent" do
      progress = described_class.progress(<<~TEXT)
        # header
        - [ ] a
        - [x] b
        - [x] c
        - [~] d
        - [-] e
        > a note
      TEXT

      expect(progress).to eq(total: 5, done: 2, inProgress: 1, skipped: 1, todo: 1, percent: 50)
    end

    it "returns 0 percent when all items are skipped" do
      progress = described_class.progress("- [-] a\n- [-] b")

      expect(progress).to include(total: 2, skipped: 2, percent: 0)
    end

    it "returns all zeros for nil" do
      expect(described_class.progress(nil))
        .to eq(total: 0, done: 0, inProgress: 0, skipped: 0, todo: 0, percent: 0)
    end
  end

  describe ".serialize" do
    it "round-trips canonical entries" do
      text = "# Section\n- [x] done\n- [~] wip\n- [-] skip\n- [ ] todo\n> note\n"

      expect(described_class.serialize(described_class.parse(text))).to eq text.chomp
    end
  end
end
