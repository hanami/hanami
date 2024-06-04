import * as assets from "hanami-assets";

await assets.run();

// To provide additional esbuild (https://esbuild.github.io) options, use the following:
//
// Read more at: https://guides.hanamirb.org/assets/customization/
//
// await assets.run({
//   esbuildOptionsFn: (args, esbuildOptions) => {
//     // Add to esbuildOptions here. Use `args.watch` as a condition for different options for
//     // compile vs watch.
//
//     return esbuildOptions;
//   }
// });
