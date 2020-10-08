require 'rails_helper'

RSpec.describe 'Panels', type: :system, js: true do
  let(:grant)       { create(:open_grant_with_users_and_form_and_submission_and_reviewer) }
  let(:admin)       { grant.admins.first  }
  let(:editor)      { grant.editors.first }
  let(:viewer)      { grant.viewers.first }
  let(:button_text) { 'Update Panel Information' }

  describe 'Edit' do
    context 'user' do
      context 'with grant_permission' do
        context 'grant_admin' do
          scenario 'can visit the edit page' do
            login_as admin, scope: admin.type.underscore.to_sym
            can_vist_edit_page(user: admin)
          end
        end

        context 'grant_editor' do
          scenario 'can visit the edit page' do
            login_as admin, scope: admin.type.underscore.to_sym
            can_vist_edit_page(user: editor)
          end
        end

        context 'grant_viewer' do
          scenario 'cannot visit the edit page' do
            login_as viewer, scope: viewer.type.underscore.to_sym
            visit edit_grant_panel_path(grant)
            expect(page).to have_content 'You are not authorized to perform this action.'
          end
        end

      end
    end
  end

  describe 'Update' do
    context 'user' do
      context 'with grant_permission' do
        context 'grant_admin' do
          before(:each) do
            login_as admin, scope: admin.type.underscore.to_sym
            # visit edit_grant_panel_path(grant)
          end

          scenario 'may update' do
            can_update_panel(user: admin)
          end
        end

        context 'grant_editor' do
          before(:each) do
            login_as editor, scope: editor.type.underscore.to_sym
          end

          scenario 'may update' do
            can_update_panel(user: editor)
          end
        end
      end
    end

    context 'instructions' do
      before(:each) do
        login_as admin, scope: admin.type.underscore.to_sym
        visit edit_grant_panel_path(grant)
      end

      scenario 'updates' do
        new_instructions = Faker::Lorem.sentence(word_count: 8)
        fill_in_trix_editor('panel_instructions', with: new_instructions)
        click_button button_text
        expect(page).to have_content 'Panel information successfully updated.'
        expect(grant.panel.instructions).to have_content new_instructions
      end
    end

    context 'meeting_link' do
      before(:each) do
        login_as admin, scope: admin.type.underscore.to_sym
        visit edit_grant_panel_path(grant)
      end

      scenario 'requires https' do
        page.fill_in 'Meeting Link', with: Faker::Internet.url(scheme: 'http')
        click_button button_text
        expect(page).to have_content 'not a valid secure URL'
      end
    end

    context 'dates' do
      before(:each) do
        login_as admin, scope: admin.type.underscore.to_sym
        visit edit_grant_panel_path(grant)
      end

      context 'start_datetime' do
        scenario 'required to be before grant submission_close_date' do
          invalid_start = (grant.submission_close_date - 1.day).at_noon
          expect do
            page.fill_in 'Start Date/Time', with: (invalid_start).strftime("%m/%d/%Y %H:%M%P")
            click_button button_text
          end.not_to change{grant.panel.start_datetime}
          expect(page).to have_content I18n.t('activerecord.errors.models.panel.attributes.start_datetime.before_submission_deadline')
        end

        scenario 'required to be before end_datetime' do
          invalid_start = Date.tomorrow.at_noon
          invalid_end   = Date.today.at_noon
          expect do
            page.fill_in 'Start Date/Time', with: invalid_start.strftime("%m/%d/%Y %H:%M%P")
            page.fill_in 'End Date/Time', with:   invalid_end.strftime("%m/%d/%Y %H:%M%P")
            click_button button_text
          end.not_to change{grant.panel.start_datetime}
          expect(page).to have_content 'must be before End Date/Time'
        end
      end
    end

    context 'paper_trail', versioning: true do
      scenario 'it tracks whodunnit' do
        login_as editor, scope: editor.type.underscore.to_sym
        visit edit_grant_panel_path(grant)
        fill_in 'Meeting Location', with: 'Edited'
        click_button button_text
        expect(grant.panel.versions.last.whodunnit).to eql editor.id
      end
    end
  end

  def can_vist_edit_page(user:)
    visit edit_grant_panel_path(grant)

    expect(page).not_to have_content 'You are not authorized to perform this action.'
  end

  def can_update_panel(user:)
    visit edit_grant_panel_path(grant)
    new_address = Faker::Address.full_address
    page.fill_in 'Meeting Location', with: new_address, fill_options: { clear: :backspace }
    click_button button_text
    expect(page).to have_content 'Panel information successfully updated.'
    expect(grant.panel.meeting_location).to eql new_address
  end

end
