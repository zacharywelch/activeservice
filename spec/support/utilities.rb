def stub_in_parallel
  Faraday::Connection.should_receive(:in_parallel).and_yield
end
