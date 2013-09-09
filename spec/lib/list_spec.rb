require 'spec_helper'

describe ActiveRecord::Acts::List do

  class ListWithInvertedPosition < ActiveRecord::Base
    self.table_name = 'mixins'
    attr_accessible :active, :parent_id, :parent_type

    # use the acts as list gem with inverted position column
    acts_as_list :inverted_position => true
  end

  class ListWithInvertedPositionTopFirst < ActiveRecord::Base
    self.table_name = 'mixins'
    attr_accessible :active, :parent_id, :parent_type

    # inverted position column and new element on top
    acts_as_list :add_new_at => :top, :inverted_position => true
  end

  describe ListWithInvertedPosition do

    # Return an array of positions in list ordered by primary key
    def list_elements
      ListWithInvertedPosition.order(:position).map(&:id)
    end

    def list_inverted_elements
      ListWithInvertedPosition.order(:inverted_position).map(&:id)
    end

    describe 'instance methods' do

      let(:subject) { ListWithInvertedPosition.new }

      it { should respond_to :inverted_position }
      it { should respond_to :has_inverted_position? }

      it { should have_inverted_position }

    end

    describe 'inverted position initial value' do

      it 'should be the opposite of position when autogenerated' do
        item = ListWithInvertedPosition.create!(:position => nil)
        item.inverted_position.should == -item.position
      end

      it 'should be the opposite of position when position is manually set' do
        item = ListWithInvertedPosition.create!(:position => 2)
        item.inverted_position.should == -2
      end

    end

    describe 'list reordering' do

      let(:subject) { ListWithInvertedPosition.find(2) }

      before(:each) do
        # List initial order by id is [1, 2, 3, 4]
        1.upto(4) { |pos| ListWithInvertedPosition.create!(:position => pos) }
        ListWithInvertedPosition.should have_a_consistent_order
      end

      # Ensure list manipulation doesn't break list order
      after { ListWithInvertedPosition.should have_a_consistent_order }

      it 'should correctly move items to a lower position' do
        expect { subject.move_lower }.to change { list_elements }.to([1, 3, 2, 4])
      end

      it 'should correctly move items in a higher position' do
        expect { subject.move_higher }.to change { list_elements }.to([2, 1, 3, 4])
      end

      it 'should correctly move items to the top of the list' do
        expect { subject.move_to_top }.to change { list_elements }.to([2, 1, 3, 4])
      end

      it 'should correctly move items to the bottom of the list' do
        expect { subject.move_to_bottom }.to change { list_elements }.to([1, 3, 4, 2])
      end

    end

  end

  describe ListWithInvertedPositionTopFirst do

    describe 'list reordering' do

      # Return an array of positions in list ordered by primary key
      def list_elements
        ListWithInvertedPosition.order(:position).pluck(:id)
      end

      before(:each) do
        1.upto(4) { |pos| ListWithInvertedPositionTopFirst.create!(:position => pos) }
        ListWithInvertedPosition.should have_a_consistent_order
      end

      # Ensure list manipulation doesn't break list order
      after { ListWithInvertedPosition.should have_a_consistent_order }

      let(:second_element) { ListWithInvertedPositionTopFirst.find(2) }

      it 'should correctly move items to a lower position' do
        expect { second_element.move_lower }.to change { list_elements }.to([4, 3, 1, 2])
      end

      it 'should correctly move items in a higher position' do
        expect { second_element.move_higher }.to change { list_elements }.to([4, 2, 3, 1])
      end

      it 'should correctly move items to the top of the list' do
        expect { second_element.move_to_top }.to change { list_elements }.to([2, 4, 3, 1])
      end

      it 'should correctly move items to the bottom of the list' do
        expect { second_element.move_to_bottom }.to change { list_elements }.to([4, 3, 1, 2])
      end

      it 'should add new elements to top and push down existing elements' do
        expect {
          ListWithInvertedPositionTopFirst.create!.should have_position(1).in_list(ListWithInvertedPositionTopFirst)
        }.to change { second_element.reload.position }.by(1)
      end

      it 'should add new elements to top and push down existing elements' do
        expect { second_element.move_lower }.to change { second_element.reload.position }.by(1)
        # Check that its position is kept in ordered list
        second_element.should have_position(second_element.position).in_list(ListWithInvertedPositionTopFirst)
      end

    end

  end

end