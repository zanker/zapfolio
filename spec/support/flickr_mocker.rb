module FlickrMocker
  def mock_flickr(args={})
    http = mock("FlickrHTTP")
    http.stub(:body).and_return(args.delete(:body))

    FlickRaw::OAuthClient.any_instance.should_receive(:post_form).with(anything, anything, anything, hash_including({"method" => "flickr.#{args.delete(:api)}"}.merge(args))).and_return(http)
  end
end