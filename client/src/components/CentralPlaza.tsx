import plazaImage from "@assets/generated_images/Kudurru_Plaza_background_image_edc6b45e.png";

export function CentralPlaza() {
  return (
    <div className="relative w-96 h-96 rounded-full border-4 border-primary/50 overflow-hidden shadow-2xl">
      <div
        className="absolute inset-0 bg-cover bg-center"
        style={{ backgroundImage: `url(${plazaImage})` }}
      />
      <div className="absolute inset-0 bg-gradient-to-b from-black/60 via-black/40 to-black/60" />
      
      <div className="absolute inset-0 flex items-center justify-center">
        <div className="text-center">
          <h2 className="font-serif text-3xl font-bold text-primary mb-2" data-testid="text-plaza-title">
            Kudurru Plaza
          </h2>
          <p className="text-sm text-primary-foreground/90">Place to unlock Last Win</p>
        </div>
      </div>

      <div className="absolute top-4 left-4 right-4 flex justify-between">
        <div className="w-12 h-12 rounded-full border-2 border-dashed border-primary/40" />
        <div className="w-12 h-12 rounded-full border-2 border-dashed border-primary/40" />
      </div>

      <div className="absolute bottom-4 left-4 right-4 flex justify-between">
        <div className="w-12 h-12 rounded-full border-2 border-dashed border-primary/40" />
        <div className="w-12 h-12 rounded-full border-2 border-dashed border-primary/40" />
      </div>
    </div>
  );
}
