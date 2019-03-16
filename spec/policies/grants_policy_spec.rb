# frozen_string_literal: true

require 'rails_helper'

describe GrantPolicy do
  subject { described_class.new(user, grant) }

  context 'with user and grant of the same organization' do
    let(:organization) { FactoryBot.create(:organization) }
    let(:grant) { FactoryBot.create(:grant, organization: organization) }

    context 'grants for organization none users' do
      let(:user) { FactoryBot.create(:user) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }

      it { is_expected.to forbid_action(:new) }
      it { is_expected.to forbid_action(:create) }
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end

    context 'grants for organization admin users' do
      let(:user) { FactoryBot.create(:user, organization_role: 'admin', organization: organization) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:new) }
      it { is_expected.to permit_action(:create) }

      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end
  context 'with user and grant of different organizations' do
    context 'grants for organization admin users' do
      let(:organization1) { FactoryBot.create(:organization) }
      let(:organization2) { FactoryBot.create(:organization) }
      let(:grant) { FactoryBot.create(:grant, organization: organization1) }
      let(:user) { FactoryBot.create(:user, organization_role: 'admin', organization: organization2) }

      it { is_expected.to permit_action(:index) }
      it { is_expected.to permit_action(:show) }
      it { is_expected.to permit_action(:new) }
      # We have stopped checking org.
      it { is_expected.to permit_action(:create) }

      # These actions are only allowed with grant access.
      it { is_expected.to forbid_action(:edit) }
      it { is_expected.to forbid_action(:update) }
      it { is_expected.to forbid_action(:destroy) }
    end
  end
end
