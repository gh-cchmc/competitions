# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'GrantUsers', type: :system do
  describe 'GrantUser', js: true do
    before(:each) do
      @organization     = create(:organization)
      @organization2    = create(:organization)
      @admin_user       = create(:user, organization: @organization,
                                        organization_role: 'none')
      @unassigned_user  = create(:user, organization: @organization)
      @grant            = create(:grant, organization: @organization)
      @grant_admin_user = create(:admin_grant_user, grant: @grant,
                                                    user: @admin_user)
      @grant_editor_user       = create(:user, organization: @organization)
      @grant_editor_user_role  = create(:editor_grant_user, grant: @grant,
                                                            user: @grant_editor_user)

      @unaffiliated_user = create(:user, organization: @organization2)
    end

    describe 'grant editor user' do
      before(:each) do
        login_as(@grant_editor_user)
      end

      context '#edit' do
        scenario 'removes edit links for user who changes their permission to viewer' do
          visit edit_grant_grant_user_path(@grant, @grant_editor_user_role)
          select('viewer', from: 'grant_user[grant_role]')
          click_button 'Update'
          expect(page).not_to have_link('Edit', href: edit_grant_grant_user_path(@grant, @grant_editor_user_role))
          expect(page).not_to have_link('Delete', href: grant_grant_user_path(@grant, @grant_editor_user_role))
          assert_equal grant_grant_users_path(@grant), current_path
        end

        scenario 'existing grant_user_editor can be assigned admin role' do
          visit edit_grant_grant_user_path(@grant.id, @grant_editor_user_role.id)
          select('admin', from: 'grant_user[grant_role]')
          click_button 'Update'
          expect(page).to have_content "#{@grant_editor_user.name}'s permission was changed to 'admin' for this grant."
        end

        scenario 'last grant_user_admin cannot be assigned a different role' do
          visit edit_grant_grant_user_path(@grant, @grant_admin_user)
          select('viewer', from: 'grant_user[grant_role]')
          click_button 'Update'
          expect(page).to have_content 'There must be at least one admin on the grant'
          expect(@grant_admin_user.grant_role).to eql('admin')
        end
      end

      context '#new' do
        scenario 'user from another organization can be given a role' do
          visit new_grant_grant_user_path(@grant.id)
          expect(page.all('select#grant_user_user_id option').map(&:value)).to include(@unaffiliated_user.id.to_s)
          select("#{@unaffiliated_user.email}", from: 'grant_user[user_id]')
          select('admin', from:'grant_user[grant_role]')
          click_button 'Save'
          expect(page).to have_content "#{@unaffiliated_user.name} was granted 'admin'"
        end

        scenario 'assigned grant_user does not appear in select' do
          visit new_grant_grant_user_path(@grant.id)
          expect(page.all('select#grant_user_user_id option').map(&:value)).not_to include(@admin_user.id.to_s)
        end

        scenario 'requires a selected user' do
          visit new_grant_grant_user_path(@grant.id)
          select('editor', from:'grant_user[grant_role]')
          click_button 'Save'
          expect(page).to have_content('User can\'t be blank')
        end

        scenario 'requires a selected user' do
          visit new_grant_grant_user_path(@grant.id)
          select("#{@unassigned_user.email}", from: 'grant_user[user_id]')
          click_button 'Save'
          expect(page).to have_content('Grant role can\'t be blank')
        end

        scenario 'unassigned user can be granted a role' do
          visit new_grant_grant_user_path(@grant.id)
          select("#{@unassigned_user.email}", from: 'grant_user[user_id]')
          select('editor', from:'grant_user[grant_role]')
          click_button 'Save'
          expect(page).to have_content "#{@unassigned_user.name} was granted 'editor'"
        end
      end
    end

    describe 'grant admin user' do
      before(:each) do
        @grant_viewer_user       = create(:user, organization: @organization)
        @grant_viewer_user_role  = create(:viewer_grant_user, grant_id: @grant.id,
                                                              user_id: @grant_viewer_user.id)
        login_as(@admin_user)
        visit grant_grant_users_path(@grant)
      end

      scenario 'cannot delete last admin grant_user' do
        expect do
          click_link('Delete', href: grant_grant_user_path(@grant, @grant_admin_user))
          page.driver.browser.switch_to.alert.accept
          expect(page).to have_content('This user\'s role cannot be deleted.')
        end.not_to change{@grant.grant_users.count}
      end

      scenario 'can delete a grant_user' do
        expect do
          expect(page).to have_content(@grant_viewer_user.name)
          click_link('Delete', href: grant_grant_user_path(@grant, @grant_viewer_user_role))
          page.driver.browser.switch_to.alert.accept
          expect(page).to have_content("#{@grant_viewer_user.name}'s role was removed for this grant.")
        end.to change{@grant.grant_users.count}.by (-1)
      end
    end

    describe 'unauthorized_user' do
      before(:each) do
        @unauthorized_user = create(:user, organization: @organization)
        @grant2            = create(:grant, organization: @organization)
        @grant2_user       = create(:admin_grant_user, grant: @grant2,
                                                       user: @unauthorized_user)

        login_as(@unauthorized_user)
      end

      scenario 'can\'t access index page' do
        visit grant_grant_users_path(@grant)
        expect(page).to have_content 'You are not authorized to perform this action.'
      end

      scenario 'can\'t access edit page' do
        visit grant_grant_users_path(@grant, @grant_admin_user)
        expect(page).to have_content 'You are not authorized to perform this action.'
      end
    end
  end
end
