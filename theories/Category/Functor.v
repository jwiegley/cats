Set Implicit Arguments.
Unset Strict Implicit.
Set Primitive Projections.
Set Universe Polymorphism.

Require Import COC.Setoid.
Require Import COC.Category.Core.

Inductive eq_Hom (C : Category)(X Y: C)(f: C X Y):
  forall (Z W: C), C Z W -> Prop :=
| eq_Hom_def:
    forall (g: C X Y), f == g -> eq_Hom f g.
Infix "=H" := eq_Hom (at level 70).

Lemma eq_Hom_refl:
  forall (C: Category)(df cf: C)(bf: C df cf),
    bf =H bf.
Proof.
  intros C df cf bf; apply eq_Hom_def; reflexivity.
Qed.

Lemma eq_Hom_symm:
  forall (C: Category)
         (df cf: C)(bf: C df cf)
         (dg cg: C)(bg: C dg cg),
    bf =H bg -> bg =H bf.
Proof.
  intros C df cf bf dg cg bg [g Heq].
  apply eq_Hom_def; apply symmetry; assumption.
Qed.

Lemma eq_Hom_trans:
  forall (C : Category)
         (df cf: C)(bf: C df cf)
         (dg cg: C)(bg: C dg cg)
         (dh ch: C)(bh: C dh ch),
    bf =H bg -> bg =H bh -> bf =H bh.
Proof.
  intros C df cf bf dg cg bg dh ch bh [g Heqg] [h Heqh].
  apply eq_Hom_def.
  transitivity g; assumption.
Qed.

(** * 函手
対象函数と射函数を構成要素として持ち、射函数は well-defined(つまり Map)。
さらに、合成と恒等射を保存。
 **)
Module Functor.
  Class spec (C D: Category)
        (fobj: C -> D)
        (fmap: forall {X Y: C}, (C X Y) -> (D (fobj X) (fobj Y))) :=
    proof {
        fmap_isMap:> forall (X Y: C), isMap (@fmap X Y) ;
        fmap_comp:
          forall (X Y Z: C)(f: C X Y)(g: C Y Z),
            fmap (g \o f) == fmap g \o fmap f;

        fmap_id:
          forall (X: C), fmap (Id X) == Id (fobj X)
      }.

  Structure type (C D: Category) :=
    make {
        fobj: C -> D;
        fmap: forall X Y: C, (C X Y) -> (D (fobj X) (fobj Y));

        prf: spec (@fmap)
      }.

  Notation build fobj fmap :=
    (@make _ _ fobj fmap (@proof _ _ fobj fmap _ _ _))
      (only parsing).

  Module Ex.
    Notation Functor := type.
    Notation isFunctor := spec.
    Coercion fobj: Functor >-> Funclass.
    Coercion prf: Functor >-> isFunctor.
    Definition fmap := fmap.
    Arguments fmap {C D}(F){X Y} _: rename, clear implicits.

    Existing Instances prf fmap_isMap.

    Notation Fmap C D F := (forall (X Y: C), (C X Y) -> (D (F X) (F Y))).

    Notation fnC := fmap_comp.
    Notation fn1 := fmap_id.

  End Ex.

  Import Ex.

  Lemma fmap_substitute:
    forall {C D: Category}(F: Functor C D){X Y: C}(f f': C X Y),
      f == f' -> fmap F f == fmap F f'.
  Proof.
    intros.
    now rewrite H.
  Qed.
  
  Program Definition compose (C D E: Category)
          (F: Functor C D)(G: Functor D E): Functor C E :=
    build _ (fun X Y f => fmap G (fmap F f)).
  Next Obligation.
    intros; intros f g Heq.
    now rewrite Heq.
  Qed.
  Next Obligation.
    now rewrite !fmap_comp.
  Qed.
  Next Obligation.
    now rewrite !fmap_id.
  Qed.

  Program Definition id (C: Category): Functor C C :=
    build _ (fun X Y f => f ) .
  Next Obligation.
    now apply Map.id.
  Qed.
  Next Obligation.
    reflexivity.
  Qed.
  Next Obligation.
    reflexivity.
  Qed.

  Definition equal {C D: Category}(F G : Functor C D) :=
    (forall (X Y: C)(f: C X Y),
      fmap F f =H fmap G f).
  Arguments equal {C D} / F G.

  Program Definition setoid (C D: Category) :=
    Setoid.build (@equal C D).
  Next Obligation.
    intros F X Y f; simpl; apply eq_Hom_refl.
  Qed.
  Next Obligation.
    intros F G Heq X Y f; simpl; apply eq_Hom_symm; apply Heq.
  Qed.
  Next Obligation.
    intros F G H HeqFG HeqGH X Y f; simpl.
    generalize (HeqGH _ _ f); simpl.
    apply eq_Hom_trans, HeqFG.
  Qed.

  Program Definition op (C D: Category)(F: Functor C D):
    Functor (Category.op C) (Category.op D) :=
    build _ (fun X Y f => fmap F f).
  Next Obligation.
    intros f f' Heq; simpl.
    now rewrite Heq.
  Qed.
  Next Obligation.
    now rewrite fmap_comp.
  Qed.
  Next Obligation.
    now rewrite fmap_id.
  Qed.
End Functor.
Export Functor.Ex.

Program Definition ConstFunctor (C: Category)(X: C): Functor C C :=
  Functor.build (fun _ => X)
                (fun (a b: C)(f: C a b) => Id_ C X).
Next Obligation.
  intros ?  ? ?; reflexivity.
Qed.
Next Obligation.
  now rewrite catC1f.
Qed.
Next Obligation.
  reflexivity.
Qed.

Definition full (C D: Category)(F: Functor C D) :=
  forall (X Y: C)(g: D (F X) (F Y)),
    exists f: C X Y, g == fmap F f.

Definition faithful (C D: Category)(F: Functor C D) :=
  forall (X Y: C)(f1 f2: C X Y),
    fmap F f1 == fmap F f2 -> f1 == f2.

Require Import COC.Category.Morphism.

Lemma fmap_monic:
  forall (C D: Category)(F: Functor C D)(X Y: C)(f: C X Y),
    faithful F -> monic (fmap F f) -> monic f.
Proof.
  unfold faithful, monic; intros.
  apply H, H0.
  now rewrite <- !Functor.fmap_comp, H1.
Qed.

