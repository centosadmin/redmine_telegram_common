require File.expand_path('../../../../test_helper', __FILE__)

class TelegramCommon::Bot::AuthenticateTest < ActiveSupport::TestCase
  fixtures :telegram_common_accounts, :users

  let(:described_class) { TelegramCommon::Bot::Authenticate }

  before do
    TelegramCommon::Utils.stubs(:auth_hash).returns('auth_hash')
  end

  context 'when user is anonymous' do
    it 'returns failure result' do
      result = described_class.new(users(:anonymous), {}).call

      expect(result.success?).must_equal false
      expect(result.value).must_equal "You're not logged in"
    end
  end

  context 'when hash is not valid' do
    it 'returns failure result' do
      result = described_class.new(users(:logged), { 'id' => 1, 'first_name' => 'test', 'last_name' => 'test', 'hash' => 'wrong_hash', 'auth_date' => Time.now.to_i }).call

      expect(result.success?).must_equal false
      expect(result.value).must_equal "Hash is invalid"
    end
  end

  context 'when hash is outdated' do
    it 'returns failure result' do
      result = described_class.new(users(:logged), { 'id' => 1, 'first_name' => 'test', 'last_name' => 'test', 'hash' => 'auth_hash', 'auth_date' => (Time.now - 61.minutes).to_i }).call

      expect(result.success?).must_equal false
      expect(result.value).must_equal "Request is outdated"
    end
  end

  context 'when telegram account found by user_id' do
    context 'when telegram ids do not match' do
      it 'returns failure result' do
        result = described_class.new(users(:logged), { 'id' => 2, 'first_name' => 'test', 'last_name' => 'test', 'hash' => 'auth_hash', 'auth_date' => Time.now.to_i }).call

        expect(result.success?).must_equal false
        expect(result.value).must_equal "Wrong Telegram account"
      end
    end

    context 'when telegram ids match' do
      it 'updates attributes and returns successful result' do
        result = described_class.new(users(:logged), { 'id' => 1, 'first_name' => 'test', 'last_name' => 'test', 'hash' => 'auth_hash', 'auth_date' => Time.now.to_i }).call

        account = TelegramCommon::Account.find(1)

        expect(result.value).must_equal account
        expect(account.first_name).must_equal 'test'
        expect(account.last_name).must_equal 'test'
        expect(result.success?).must_equal true
      end
    end
  end

  context 'when telegram account not found by user_id' do
    context 'when user ids do not match' do
      it 'returns failure result' do
        result = described_class.new(users(:user_3), { 'id' => 1, 'first_name' => 'test', 'last_name' => 'test', 'hash' => 'auth_hash', 'auth_date' => Time.now.to_i }).call

        expect(result.success?).must_equal false
        expect(result.value).must_equal "Wrong Telegram account"
      end
    end

    context 'when telegram account does not have user_id' do
      it 'updates attributes and returns successful result' do
        result = described_class.new(users(:user_3), { 'id' => 3, 'first_name' => 'test', 'last_name' => 'test', 'hash' => 'auth_hash', 'auth_date' => Time.now.to_i }).call

        account = TelegramCommon::Account.last

        expect(result.value).must_equal account
        expect(account.user_id).must_equal users(:user_3).id
        expect(account.first_name).must_equal 'test'
        expect(account.last_name).must_equal 'test'
        expect(result.success?).must_equal true
      end
    end
  end
end
