# Build on your own

run `build_curl.sh`

Remember to change the NDK path to your path.

Also, after building `openssl` and `zlib`, we need to comment out them, and then build for curl with `pie` support.

# Direct install (not guarantee working)

run `install_curl_from_lib.sh`

# Notes

I did not bother about openssl.. somehow it does not support pie and will report errors. Need tweaks there but since I only need partial functions of `curl`, I did not solve that, and not even trying to install `openssl` later. I hope someone with more knowledge will help solve the compilation issue soon.

# References

* https://wiki.openssl.org/images/7/70/Setenv-android.sh
