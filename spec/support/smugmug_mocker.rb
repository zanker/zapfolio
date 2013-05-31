module SmugMugMocker
  def mock_smugmug(api, contents, body)
    SmugMug::HTTP.any_instance.should_receive(:request).with(api, hash_including(contents)).and_return(body)
  end
end