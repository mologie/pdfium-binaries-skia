#!/bin/bash -eux

PDFium_URL='https://pdfium.googlesource.com/pdfium.git'
OS=${PDFium_TARGET_OS:?}
ENABLE_V8=${PDFium_ENABLE_V8:-false}
USE_SKIA=${PDFium_USE_SKIA:-true}

CONFIG_ARGS=()
if [ "$ENABLE_V8" == "false" ]; then
  CONFIG_ARGS+=(
     --custom-var "checkout_configuration=minimal"
  )
  # minimal drops Skia too; re-add it without pulling V8
  if [ "$USE_SKIA" == "true" ]; then
    CONFIG_ARGS+=(
       --custom-var "checkout_skia=true"
    )
  fi
fi

# Clone
gclient config --unmanaged "$PDFium_URL" "${CONFIG_ARGS[@]-}"
echo "target_os = [ '$OS' ]" >> .gclient
# gclient writes custom vars as strings; BUILD.gn needs checkout_skia boolean
# (plain sed, not sed -i, for BSD/GNU portability)
if [ "$USE_SKIA" == "true" ] && [ "$ENABLE_V8" == "false" ]; then
  sed "s/'checkout_skia': 'true'/'checkout_skia': True/" .gclient > .gclient.tmp && mv .gclient.tmp .gclient
fi


# Reset
for FOLDER in pdfium pdfium/build pdfium/v8 pdfium/third_party/libjpeg_turbo pdfium/base/allocator/partition_allocator; do
  if [ -e "$FOLDER" ]; then
    git -C $FOLDER reset --hard
    git -C $FOLDER clean -df
  fi
done

gclient sync -r "origin/${PDFium_BRANCH:-main}" --no-history --shallow
