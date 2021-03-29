class CopySubmitterToApplicant < ActiveRecord::Migration[6.0]
  def up
    GrantSubmission::Submission.all.each do |submission|
      GrantSubmission::Submission::Applicant.create!(grant_submission_submission_id: submission.id,
                                          user_id: submission.submitter.id,
                                          role: 'primary')
    end
  end

  def down
    # There is no way to undo this and will be "fixed" once the table is removed in
    # a rollback of migration 20210322143522_create_grant_submission_applicants.rb.
  end
end
