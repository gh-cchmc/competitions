require 'rails_helper'

RSpec.describe GrantReviewerServices do
  describe 'DeleteReviewer' do
    before(:each) do
      @grant          = create(:open_grant_with_users_and_form_and_submission_and_reviewer)
      @grant_admin    = @grant.grant_permissions.role_admin.first.user
      @grant_reviewer = @grant.grant_reviewers.first
      @review         = create(:review, submission: @grant.submissions.first,
                                        assigner: @grant_admin,
                                        reviewer: @grant_reviewer.reviewer)
    end

    context 'success' do
      it 'removes a reviewer from the grant' do
        expect do
          GrantReviewerServices::DeleteReviewer.call(grant_reviewer: @grant_reviewer)
        end.to (change{GrantReviewer.count}.by (-1))
      end

      it "deletes reviewer's reviews from the grant" do
        expect do
          GrantReviewerServices::DeleteReviewer.call(grant_reviewer: @grant_reviewer)
        end.to (change{@grant.reviews.count}.by (-1))
      end

      it 'does not delete reviews from other grant' do
        other_grant    = create(:open_grant_with_users_and_form_and_submission_and_reviewer)
        other_reviewer = create(:grant_reviewer, grant: other_grant,
                                                 reviewer: @grant_reviewer.reviewer)
        other_review   = create(:review, submission: other_grant.submissions.first,
                                          assigner: other_grant.editors.first,
                                          reviewer: @grant_reviewer.reviewer)
        reviewer = @grant_reviewer.reviewer

        expect do
          GrantReviewerServices::DeleteReviewer.call(grant_reviewer: @grant_reviewer)
        end.to change{reviewer.reviews.by_grant(other_grant).count}.by(0).and change{reviewer.reviews.by_grant(@grant).count}.by(-1)
      end
    end

    context 'failure' do
      it "does not delete reviews on failure" do
        allow_any_instance_of(GrantReviewer).to receive(:destroy!).and_raise(StandardError)
        expect do
          GrantReviewerServices::DeleteReviewer.call(grant_reviewer: @grant_reviewer)
        end.not_to change{Review.count}
      end

      it "does not delete grant_reviewer on failure" do
        allow_any_instance_of(GrantReviewer).to receive(:destroy!).and_raise(StandardError)
        expect do
          GrantReviewerServices::DeleteReviewer.call(grant_reviewer: @grant_reviewer)
        end.not_to change{@grant.grant_reviewers.count}
      end

      it "does not delete reviewer's reviews on failure" do
        allow_any_instance_of(Review).to receive(:destroy).and_raise(StandardError)
        expect do
          GrantReviewerServices::DeleteReviewer.call(grant_reviewer: @grant_reviewer)
        end.not_to change{@grant.grant_reviewers.count}
      end

      it "does not delete reviewer's reviews on failure" do
        allow_any_instance_of(Review).to receive(:destroy).and_raise(StandardError)
        expect do
          GrantReviewerServices::DeleteReviewer.call(grant_reviewer: @grant_reviewer)
        end.not_to change{@grant.reviews.count}
      end
    end
  end
end
