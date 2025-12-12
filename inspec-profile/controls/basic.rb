control "sshd-1" do
  impact 1.0
  title "SSH root login disabled"
  desc "STIG requirement: SSH must not allow root login"

  describe sshd_config do
    its('PermitRootLogin') { should cmp 'no' }
  end
end

control "auditd-1" do
  impact 1.0
  title "Auditd must be running"
  desc "STIG requirement: auditd service must stay active"

  describe service('auditd') do
    it { should be_enabled }
    it { should be_running }
  end
end
