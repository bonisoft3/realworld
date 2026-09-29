// Browser-tier twin of tag-recount.blobl — a stub that throws, for the reason
// stated in favorite-recount.browser.js
// (ir decision-browser-tier-unsupported).
export default () => {
  throw new Error(
    "tag-recount: the browser tier is unsupported (ir decision-browser-tier-unsupported). This pipeline emits an array of tag_count rows, one per distinct tag; the browser shim contract is (rows) => one row upserted on id. Run the container tier.",
  );
};
